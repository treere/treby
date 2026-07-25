defmodule Treby.BulkOperations do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Application

  def bulk_move_stage(application_ids, pipeline_stage_id, tenant_id) do
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
    # Get candidate IDs from applications
    candidate_ids =
      Application
      |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
      |> select([a], a.candidate_id)
      |> Repo.all()
      |> Enum.uniq()

    # Delete applications first
    Application
    |> where([a], a.id in ^application_ids and a.tenant_id == ^tenant_id)
    |> Repo.delete_all()

    # Delete candidates that have no remaining applications
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

  def bulk_send_email(application_ids, subject, body, tenant_id) do
    # Get candidates with their applications
    candidates_with_apps =
      Application
      |> join(:inner, [a], c in Treby.Candidates.Candidate, on: a.candidate_id == c.id)
      |> where([a, c], a.id in ^application_ids and a.tenant_id == ^tenant_id)
      |> select([a, c], %{candidate: c, application: a})
      |> Repo.all()

    results =
      Enum.map(candidates_with_apps, fn %{candidate: candidate} ->
        personalized_body =
          body
          |> String.replace("{candidate_name}", candidate.name || "")

        case Treby.EmailTemplates.send_stage_email(nil, candidate, nil, %{
               subject: subject,
               body: personalized_body
             }) do
          :ok -> {:ok, candidate.email}
          {:error, reason} -> {:error, candidate.email, reason}
        end
      end)

    successes = Enum.filter(results, &match?({:ok, _}, &1))
    failures = Enum.filter(results, &match?({:error, _, _}, &1))

    {:ok, %{sent: length(successes), failed: length(failures)}}
  end
end
