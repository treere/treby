defmodule Treby.Authorization.RolePermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "role_permissions" do
    field :role, :string
    field :action, :string
    field :allowed, :boolean, default: true

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:tenant_id, :role, :action, :allowed])
    |> validate_required([:tenant_id, :role, :action, :allowed])
    |> validate_inclusion(:role, ~w(recruiter interviewer))
    |> validate_inclusion(
      :action,
      Treby.Authorization.editable_actions() |> Enum.map(&to_string/1)
    )
    |> unique_constraint([:tenant_id, :role, :action])
    |> foreign_key_constraint(:tenant_id)
  end
end
