defmodule Treby.Customization.CustomField do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "custom_fields" do
    field :name, :string
    field :field_type, :string, default: "text"
    field :applies_to, :string
    field :options, {:array, :string}, default: []
    field :required, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(custom_field, attrs) do
    custom_field
    |> cast(attrs, [:name, :field_type, :applies_to, :options, :required, :position, :tenant_id])
    |> validate_required([:name, :field_type, :applies_to, :tenant_id])
    |> validate_inclusion(:field_type, ~w(text number date select url))
    |> validate_inclusion(:applies_to, ~w(candidate job application))
  end
end
