defmodule Mix.Tasks.Treby.Notifications.Backfill do
  @shortdoc "Backfills notifications from recent activity_log (30d)"

  @moduledoc """
  Idempotent backfill that maps recent `activity_log` (last 30 days) actions → notification types,
  inserts for current tenant members where inbox is enabled.

  Usage:
    mix treby.notifications.backfill [--dry-run]
  """

  use Mix.Task
  import Ecto.Query, warn: false

  alias Treby.Notifications
  alias Treby.Notifications.Notification

  @action_to_type %{
    "new_application" => "new_application",
    "application_stage_changed" => "stage_change",
    "interview_scheduled" => "interview_scheduled",
    "interview_cancelled" => "interview_cancelled",
    "candidate_created" => "candidate_created"
  }

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    dry_run? = "--dry-run" in args

    cutoff = DateTime.add(DateTime.utc_now(), -30 * 24 * 60 * 60, :second)

    logs =
      Treby.Activities.ActivityLog
      |> where([a], a.inserted_at >= ^cutoff)
      |> where([a], a.action in ^Map.keys(@action_to_type))
      |> Treby.Repo.all()

    if logs == [] do
      Mix.shell().info("No mappable activity_log rows in last 30 days.")
    else
      grouped = Enum.group_by(logs, & &1.tenant_id)

      total =
        Enum.reduce(grouped, 0, fn {tenant_id, tenant_logs}, acc ->
          tenant = Treby.Repo.get(Treby.Tenants.Tenant, tenant_id)

          if is_nil(tenant) do
            acc
          else
            members = Treby.Memberships.list_users_for_tenant(tenant_id)

            Enum.reduce(tenant_logs, acc, fn log, acc2 ->
              type = Map.get(@action_to_type, log.action)

              if type && Notifications.inbox_enabled?(tenant, type) do
                title = build_title(log, type)
                body = log.metadata["job_title"] || log.metadata[:job_title] || ""
                link = build_link(log)

                # dedup: per-recipient check, idempotent per (tenant, recipient, type, link, window)
                {inserted, _} =
                  Enum.reduce(members, {0, []}, fn user, {cnt, _} ->
                    exists? =
                      Treby.Repo.exists?(
                        from n in Notification,
                          where:
                            n.tenant_id == ^tenant_id and n.recipient_id == ^user.id and
                              n.type == ^type and n.link == ^link and n.inserted_at >= ^cutoff
                      )

                    if exists? do
                      {cnt, []}
                    else
                      if dry_run? do
                        Mix.shell().info(
                          "[dry-run] would insert #{type} for user #{user.id} tenant #{tenant_id} link #{link}"
                        )

                        {cnt + 1, []}
                      else
                        now = DateTime.utc_now() |> DateTime.truncate(:second)

                        notification = %Notification{
                          id: Ecto.UUID.generate(),
                          tenant_id: tenant_id,
                          recipient_id: user.id,
                          type: type,
                          title: title,
                          body: body,
                          link: link,
                          read_at: nil,
                          inserted_at: now,
                          updated_at: now
                        }

                        case Treby.Repo.insert(notification) do
                          {:ok, n} ->
                            Phoenix.PubSub.broadcast(
                              Treby.PubSub,
                              "notifications:#{user.id}",
                              {:new_notification, n}
                            )

                            {cnt + 1, []}

                          _ ->
                            {cnt, []}
                        end
                      end
                    end
                  end)

                acc2 + inserted
              else
                acc2
              end
            end)
          end
        end)

      Mix.shell().info(
        "Backfill complete. #{if dry_run?, do: "Would insert", else: "Inserted"} #{total} notifications (fan-out counted)."
      )
    end
  end

  defp build_title(log, type) do
    case type do
      "new_application" ->
        "New application: #{log.metadata["candidate_name"] || "candidate"} — #{log.metadata["job_title"] || ""}"

      "stage_change" ->
        "Stage changed: #{log.metadata["new_stage"] || log.metadata["stage_name"] || ""}"

      "interview_scheduled" ->
        "Interview scheduled"

      "interview_cancelled" ->
        "Interview cancelled"

      _ ->
        String.replace(type, "_", " ") |> String.capitalize()
    end
  end

  defp build_link(log) do
    case log.entity_type do
      "application" -> "/app/candidates/#{log.entity_id}"
      "candidate" -> "/app/candidates/#{log.entity_id}"
      _ -> nil
    end
  end
end
