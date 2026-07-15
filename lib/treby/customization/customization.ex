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

  def create_custom_field(attrs \\ %{}) do
    %CustomField{}
    |> CustomField.changeset(attrs)
    |> Repo.insert()
  end

  def update_custom_field(%CustomField{} = custom_field, attrs) do
    custom_field
    |> CustomField.changeset(attrs)
    |> Repo.update()
  end

  def delete_custom_field(%CustomField{} = custom_field) do
    Repo.delete(custom_field)
  end

  def change_custom_field(%CustomField{} = custom_field, attrs \\ %{}) do
    CustomField.changeset(custom_field, attrs)
  end
end
