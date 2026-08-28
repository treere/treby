defmodule Treby.BulkOperations do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Application

  def bulk_move_stage(application_ids, pipeline_stage_id, tenant_id, _actor \\ nil) do
    Application
    |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
    |> Repo.update_all(set: [pipeline_stage_id: pipeline_stage_id])
  end

  def bulk_mark_reviewed(application_ids, tenant_id) do
    Application
    |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
    |> Repo.update_all(set: [reviewed: true])
  end

  def bulk_mark_unreviewed(application_ids, tenant_id) do
    Application
    |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
    |> Repo.update_all(set: [reviewed: false])
  end

  def bulk_delete_candidates(application_ids, tenant_id) do
    candidate_ids =
      Application
      |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
      |> select([a], a.candidate_id)
      |> Repo.all()
      |> Enum.uniq()

    Application
    |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
    |> Repo.delete_all()

    alias Treby.Candidates.Candidate

    Enum.each(candidate_ids, fn candidate_id ->
      remaining =
        Application
        |> where([a], a.candidate_id == ^candidate_id)
        |> select([a], count(a.id))
        |> Repo.one()

      if remaining == 0 do
        Candidate |> where([c], c.id == ^candidate_id) |> Repo.delete_all()
      end
    end)

    {:ok, length(application_ids)}
  end

  def bulk_send_message(application_ids, body, tenant_id, opts \\ []) do
    candidates_with_apps =
      Application
      |> join(:inner, [a], c in Treby.Candidates.Candidate, on: a.candidate_id == c.id)
      |> where([a, c], a.id in ^application_ids and a.tenant_id == ^tenant_id)
      |> select([a, c], %{candidate: c, application: a})
      |> Repo.all()

    if schedule = opts[:schedule] do
      bulk_send_scheduled(candidates_with_apps, body, tenant_id, schedule)
    else
      bulk_send_immediate(candidates_with_apps, body)
    end
  end

  defp bulk_send_immediate(candidates_with_apps, body) do
    results =
      Enum.map(candidates_with_apps, fn %{candidate: candidate, application: application} ->
        personalized_body =
          body
          |> String.replace("{candidate_name}", candidate.name || "")

        conversation_id = conversation_for_application(candidate, application, personalized_body)

        case Treby.CandidatePortal.send_message(%{
               sender_type: "recruiter",
               conversation_id: conversation_id,
               body: personalized_body,
               message_type: "text",
               metadata: %{"bulk" => true}
             }) do
          {:ok, _message} -> {:ok, candidate.email}
          {:error, _} -> {:error, candidate.email, "failed to post message"}
        end
      end)

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    failures = Enum.filter(results, &match?({:error, _, _}, &1))
    skipped = Enum.count(results, &(&1 == :skipped))

    {:ok, %{sent: length(successes), failed: length(failures), skipped: skipped}}
  end

  defp bulk_send_scheduled(candidates_with_apps, body, tenant_id, schedule) do
    scheduled_at = schedule.scheduled_at
    jitter_minutes = schedule[:jitter_minutes] || 0

    results =
      Enum.map(candidates_with_apps, fn %{candidate: candidate, application: application} ->
        personalized_body =
          body
          |> String.replace("{candidate_name}", candidate.name || "")

        conversation_id = conversation_for_application(candidate, application, personalized_body)

        send_at = apply_jitter(scheduled_at, jitter_minutes)

        case Treby.ScheduledMessages.create_scheduled_message(%{
               tenant_id: tenant_id,
               sender_type: "recruiter",
               conversation_id: conversation_id,
               body: personalized_body,
               message_type: "text",
               metadata: %{"bulk" => true},
               send_at: send_at
             }) do
          {:ok, _scheduled_message} -> {:ok, candidate.email}
          {:error, _} -> {:error, candidate.email, "failed to create scheduled message"}
        end
      end)

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    failures = Enum.filter(results, &match?({:error, _, _}, &1))
    skipped = Enum.count(results, &(&1 == :skipped))

    {:ok, %{sent: length(successes), failed: length(failures), skipped: skipped}}
  end

  defp conversation_for_application(candidate, application, body) do
    existing =
      Treby.CandidatePortal.list_conversations_for_application(
        application.id,
        application.tenant_id
      )

    case Enum.find(existing, &(&1.context == "application")) do
      nil ->
        subject =
          body
          |> String.slice(0, 80)
          |> String.replace("\n", " ")

        {:ok, conversation} =
          Treby.CandidatePortal.create_conversation(%{
            candidate_id: candidate.id,
            tenant_id: application.tenant_id,
            application_id: application.id,
            subject: subject || "Message",
            context: "application"
          })

        conversation.id

      conversation ->
        conversation.id
    end
  end

  defp apply_jitter(scheduled_at, 0), do: scheduled_at

  defp apply_jitter(scheduled_at, jitter_minutes) when jitter_minutes > 0 do
    offset_seconds = :rand.uniform(2 * jitter_minutes * 60) - jitter_minutes * 60
    DateTime.add(scheduled_at, offset_seconds, :second)
  end
end
