defmodule Treby.BulkOperations do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Application
  alias Treby.EmailQueue

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

  def bulk_send_email(application_ids, subject, body, tenant_id, opts \\ []) do
    candidates_with_apps =
      Application
      |> join(:inner, [a], c in Treby.Candidates.Candidate, on: a.candidate_id == c.id)
      |> where([a, c], a.id in ^application_ids and a.tenant_id == ^tenant_id)
      |> select([a, c], %{candidate: c, application: a})
      |> Repo.all()

    if schedule = opts[:schedule] do
      bulk_send_scheduled(candidates_with_apps, subject, body, tenant_id, schedule)
    else
      bulk_send_immediate(candidates_with_apps, subject, body)
    end
  end

  defp bulk_send_immediate(candidates_with_apps, subject, body) do
    results =
      Enum.map(candidates_with_apps, fn %{candidate: candidate} ->
        personalized_body =
          body
          |> String.replace("{candidate_name}", candidate.name || "")

        if candidate.email in [nil, ""] do
          :skipped
        else
          email =
            Swoosh.Email.new()
            |> Swoosh.Email.to(candidate.email)
            |> Swoosh.Email.from("noreply@treby.app")
            |> Swoosh.Email.subject(subject)
            |> Swoosh.Email.text_body(personalized_body)

          case Treby.Mailer.deliver(email) do
            {:ok, _result} -> {:ok, candidate.email}
            {:error, reason} -> {:error, candidate.email, reason}
          end
        end
      end)

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    failures = Enum.filter(results, &match?({:error, _, _}, &1))
    skipped = Enum.count(results, &(&1 == :skipped))

    {:ok, %{sent: length(successes), failed: length(failures), skipped: skipped}}
  end

  defp bulk_send_scheduled(candidates_with_apps, subject, body, tenant_id, schedule) do
    scheduled_at = schedule.scheduled_at
    jitter_minutes = schedule[:jitter_minutes] || 0

    results =
      Enum.map(candidates_with_apps, fn %{candidate: candidate} ->
        personalized_body =
          body
          |> String.replace("{candidate_name}", candidate.name || "")

        if candidate.email in [nil, ""] do
          :skipped
        else
          case EmailQueue.create_scheduled_email(%{
                 tenant_id: tenant_id,
                 scheduled_at: scheduled_at,
                 jitter_minutes: jitter_minutes,
                 to_address: candidate.email,
                 from_address: "noreply@treby.app",
                 subject: subject,
                 body: personalized_body,
                 email_type: "bulk"
               }) do
            {:ok, scheduled_email} ->
              EmailQueue.schedule_delivery!(scheduled_email)
              {:ok, candidate.email}

            {:error, _} ->
              {:error, candidate.email, "failed to create scheduled email"}
          end
        end
      end)

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    failures = Enum.filter(results, &match?({:error, _, _}, &1))
    skipped = Enum.count(results, &(&1 == :skipped))

    {:ok, %{sent: length(successes), failed: length(failures), skipped: skipped}}
  end
end
