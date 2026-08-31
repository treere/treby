defmodule Treby.Sources do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Sources.Source

  def list_sources(tenant_id) do
    Source
    |> where([s], s.tenant_id == ^tenant_id)
    |> order_by([s], s.position)
    |> Repo.all()
  end

  def get_source!(id), do: Repo.get!(Source, id)

  def get_source!(tenant_id, id) do
    Source
    |> where([s], s.tenant_id == ^tenant_id and s.id == ^id)
    |> Repo.one!()
  end

  def create_source(attrs \\ %{}) do
    case %Source{} |> Source.changeset(attrs) |> Repo.insert() do
      {:ok, source} ->
        Treby.Audit.log_event("source.created", "source", source.id, %{
          tenant_id: source.tenant_id,
          metadata: %{after: %{name: source.name}}
        })

        {:ok, source}

      error ->
        error
    end
  end

  def update_source(%Source{} = source, attrs) do
    old_name = source.name

    source
    |> Source.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} when old_name != updated.name ->
        # Update all applications using the old source name to the new name
        import Ecto.Query
        alias Treby.Pipeline.Application

        Application
        |> where([a], a.source == ^old_name and a.tenant_id == ^updated.tenant_id)
        |> Repo.update_all(set: [source: updated.name])

        {:ok, updated}

      result ->
        result
    end
  end

  def delete_source(%Source{} = source) do
    # Re-tag applications using this source as "Other"
    other_source = default_source(source.tenant_id)

    import Ecto.Query
    alias Treby.Pipeline.Application

    Application
    |> where([a], a.source == ^source.name and a.tenant_id == ^source.tenant_id)
    |> Repo.update_all(set: [source: other_source.name])

    case Repo.delete(source) do
      {:ok, deleted} ->
        Treby.Audit.log_event("source.deleted", "source", deleted.id, %{
          tenant_id: deleted.tenant_id,
          metadata: %{before: %{name: deleted.name}}
        })

        {:ok, deleted}

      error ->
        error
    end
  end

  def default_source(tenant_id) do
    Source
    |> where([s], s.tenant_id == ^tenant_id and s.name == "Other")
    |> Repo.one()
    |> case do
      nil ->
        # Fallback: just return an in-memory struct
        %Source{name: "Other", tenant_id: tenant_id, is_default: true}

      source ->
        source
    end
  end
end
