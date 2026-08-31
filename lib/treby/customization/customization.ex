defmodule Treby.Customization do
  @moduledoc """
  The Customization context - manages custom fields.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Customization.CustomField

  def list_custom_fields(tenant_id) do
    CustomField
    |> where([cf], cf.tenant_id == ^tenant_id)
    |> order_by([cf], cf.position)
    |> Repo.all()
  end

  def list_custom_fields_for(tenant_id, applies_to) do
    CustomField
    |> where([cf], cf.tenant_id == ^tenant_id and cf.applies_to == ^applies_to)
    |> order_by([cf], cf.position)
    |> Repo.all()
  end

  def get_custom_field!(id), do: Repo.get!(CustomField, id)

  def get_custom_field!(tenant_id, id) do
    CustomField
    |> where([cf], cf.tenant_id == ^tenant_id and cf.id == ^id)
    |> Repo.one!()
  end

  def create_custom_field(attrs \\ %{}, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      case %CustomField{} |> CustomField.changeset(attrs) |> Repo.insert() do
        {:ok, cf} ->
          Treby.Audit.log_event("custom_field.created", "custom_field", cf.id, %{
            tenant_id: cf.tenant_id,
            actor_id: actor && actor.id,
            metadata: %{after: %{name: cf.name, applies_to: cf.applies_to}}
          })

          {:ok, cf}

        error ->
          error
      end
    end
  end

  def update_custom_field(%CustomField{} = custom_field, attrs, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      before = Map.take(custom_field, [:name, :applies_to])

      case custom_field |> CustomField.changeset(attrs) |> Repo.update() do
        {:ok, updated} ->
          Treby.Audit.log_event("custom_field.updated", "custom_field", updated.id, %{
            tenant_id: updated.tenant_id,
            actor_id: actor && actor.id,
            metadata: %{before: before, after: Map.take(updated, [:name, :applies_to])}
          })

          {:ok, updated}

        error ->
          error
      end
    end
  end

  def delete_custom_field(%CustomField{} = custom_field, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      case Repo.delete(custom_field) do
        {:ok, deleted} ->
          Treby.Audit.log_event("custom_field.deleted", "custom_field", deleted.id, %{
            tenant_id: deleted.tenant_id,
            actor_id: actor && actor.id,
            metadata: %{before: %{name: deleted.name}}
          })

          {:ok, deleted}

        error ->
          error
      end
    end
  end

  def change_custom_field(%CustomField{} = custom_field, attrs \\ %{}) do
    CustomField.changeset(custom_field, attrs)
  end
end
