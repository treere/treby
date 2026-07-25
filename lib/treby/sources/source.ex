defmodule Treby.Sources.Source do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "sources" do
    field :name, :string
    field :is_default, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:name, :is_default, :position, :tenant_id])
    |> validate_required([:name, :tenant_id])
    |> unique_constraint([:tenant_id, :name])
  end
end
