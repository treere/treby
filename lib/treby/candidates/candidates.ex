defmodule Treby.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate

  def list_candidates(tenant_id, filters \\ %{}) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id)
    |> apply_search(filters[:search])
    |> apply_job_filter(filters[:job_id])
    |> apply_stage_filter(filters[:stage_id])
    |> order_by([c], c.name)
    |> Repo.all()
  end

  defp apply_search(query, nil), do: query
  defp apply_search(query, ""), do: query

  defp apply_search(query, search) do
    pattern = "%#{search}%"

    query
    |> where([c], ilike(c.name, ^pattern) or ilike(c.email, ^pattern))
  end

  defp apply_job_filter(query, nil), do: query
  defp apply_job_filter(query, ""), do: query

  defp apply_job_filter(query, job_id) do
    import Ecto.Query

    subquery =
      Treby.Pipeline.Application
      |> where([a], a.job_id == ^job_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end

  defp apply_stage_filter(query, nil), do: query
  defp apply_stage_filter(query, ""), do: query

  defp apply_stage_filter(query, stage_id) do
    import Ecto.Query

    subquery =
      Treby.Pipeline.Application
      |> where([a], a.pipeline_stage_id == ^stage_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end

  def get_candidate!(id), do: Repo.get!(Candidate, id)

  def get_candidate!(tenant_id, id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and c.id == ^id)
    |> Repo.one!()
  end

  def find_or_create_candidate(tenant_id, attrs) do
    email = String.downcase(attrs["email"] || attrs[:email])

    case Repo.get_by(Candidate, tenant_id: tenant_id, email: email) do
      nil -> create_candidate(Map.put(attrs, "tenant_id", tenant_id))
      candidate -> {:ok, candidate}
    end
  end

  def create_candidate(attrs \\ %{}) do
    tenant_id = attrs["tenant_id"] || attrs[:tenant_id]

    result =
      %Candidate{tenant_id: tenant_id}
      |> Candidate.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, candidate} ->
        Treby.Activities.log_event(
          "candidate_created",
          "candidate",
          candidate.id,
          %{tenant_id: candidate.tenant_id}
        )

        {:ok, candidate}

      error ->
        error
    end
  end

  def update_candidate(%Candidate{} = candidate, attrs, metadata \\ %{}) do
    result =
      candidate
      |> Candidate.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        Treby.Activities.log_event(
          "candidate_updated",
          "candidate",
          updated.id,
          Map.merge(metadata, %{tenant_id: updated.tenant_id})
        )

        {:ok, updated}

      error ->
        error
    end
  end

  def delete_candidate(%Candidate{} = candidate, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(candidate)
    end
  end

  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end
end
