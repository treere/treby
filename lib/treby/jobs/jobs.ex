defmodule Treby.Jobs do
  @moduledoc """
  The Jobs context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Jobs.Job

  def list_jobs(tenant_id) do
    Job
    |> where([j], j.tenant_id == ^tenant_id)
    |> order_by([j], desc: j.inserted_at)
    |> Repo.all()
  end

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
    ilike_query = "%#{query}%"

    Job
    |> where(
      [j],
      j.tenant_id == ^tenant_id and j.status == "open" and j.visible == true and
        (ilike(j.title, ^ilike_query) or ilike(j.description, ^ilike_query))
    )
    |> order_by([j], j.title)
    |> Repo.all()
  end

  def search_all_visible_jobs(query) do
    ilike_query = "%#{query}%"

    Job
    |> join(:inner, [j], t in assoc(j, :tenant))
    |> where(
      [j, t],
      j.status == "open" and j.visible == true and
        (ilike(j.title, ^ilike_query) or ilike(j.description, ^ilike_query))
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

  def create_job(attrs \\ %{}) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end

  def update_job(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end
end
