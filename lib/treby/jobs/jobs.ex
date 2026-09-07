defmodule Treby.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias Treby.Candidates.Queries
  alias Treby.Repo
  alias Treby.Jobs.Job

  @doc """
  Lists jobs for a tenant, newest first.

  Without `:page` in `opts` returns the full list; with `:page` returns
  `{entries, page_info}` (see `Treby.Candidates.Queries.paginate/3`).
  `:status` in `opts` (`"open"`/`"closed"`) filters by status.
  """
  def list_jobs(tenant_id, opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Job
      |> where([j], j.tenant_id == ^tenant_id)
      |> apply_status_filter(opts[:status])
      |> order_by([j], desc: j.inserted_at, desc: j.id)

    case opts[:page] do
      nil -> Repo.all(query)
      page -> Queries.paginate(query, page, opts[:page_size])
    end
  end

  defp apply_status_filter(query, status) when status in ["open", "closed"] do
    where(query, [j], j.status == ^status)
  end

  defp apply_status_filter(query, _), do: query

  def list_open_jobs(tenant_id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id and j.status == "open")
    |> order_by([j], j.title)
    |> Repo.all()
  end

  def list_visible_jobs(tenant_id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id and j.status == "open" and j.visible == true)
    |> order_by([j], j.title)
    |> Repo.all()
  end

  def list_all_visible_jobs do
    Job
    |> join(:inner, [j], t in assoc(j, :tenant))
    |> where([j, t], j.status == "open" and j.visible == true)
    |> preload([j, t], tenant: t)
    |> order_by([j, t], asc: t.name, asc: j.title)
    |> Repo.all()
  end

  def search_visible_jobs(tenant_id, query) do
    ilike_query = "%#{Queries.escape_like(query)}%"

    Job
    |> where(
      [j],
      j.tenant_id == ^tenant_id and j.status == "open" and j.visible == true and
        (ilike(j.title, ^ilike_query) or ilike(j.description, ^ilike_query) or
           ilike(j.location, ^ilike_query))
    )
    |> order_by([j], j.title)
    |> Repo.all()
  end

  def search_all_visible_jobs(query) do
    ilike_query = "%#{Queries.escape_like(query)}%"

    Job
    |> join(:inner, [j], t in assoc(j, :tenant))
    |> where(
      [j, t],
      j.status == "open" and j.visible == true and
        (ilike(j.title, ^ilike_query) or ilike(j.description, ^ilike_query) or
           ilike(j.location, ^ilike_query))
    )
    |> preload([j, t], tenant: t)
    |> order_by([j, t], asc: t.name, asc: j.title)
    |> Repo.all()
  end

  def get_job!(id), do: Repo.get!(Job, id)

  def get_job!(tenant_id, id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id and j.id == ^id)
    |> Repo.one!()
  end

  def get_job(tenant_id, id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id and j.id == ^id)
    |> Repo.one()
  end

  def create_job(attrs \\ %{}) do
    tenant_id = attrs["tenant_id"] || attrs[:tenant_id]

    case %Job{tenant_id: tenant_id} |> Job.changeset(attrs) |> Repo.insert() do
      {:ok, job} ->
        Treby.Audit.log_event("job.created", "job", job.id, %{
          tenant_id: job.tenant_id,
          actor_id: attrs["actor_id"] || attrs[:actor_id],
          metadata: %{after: Map.take(job, [:title, :status])}
        })

        {:ok, job}

      error ->
        error
    end
  end

  def update_job(%Job{} = job, attrs) do
    before = Map.take(job, [:title, :status, :visible])

    case job |> Job.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        Treby.Audit.log_event("job.updated", "job", updated.id, %{
          tenant_id: updated.tenant_id,
          actor_id: attrs["actor_id"] || attrs[:actor_id],
          metadata: %{before: before, after: Map.take(updated, [:title, :status, :visible])}
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def delete_job(%Job{} = job) do
    case Repo.delete(job) do
      {:ok, deleted} ->
        Treby.Audit.log_event("job.deleted", "job", deleted.id, %{
          tenant_id: deleted.tenant_id,
          metadata: %{before: %{title: deleted.title}}
        })

        {:ok, deleted}

      error ->
        error
    end
  end

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  def tenant_has_jobs?(tenant_id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id)
    |> Repo.exists?()
  end
end
