defmodule Treby.Memberships.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "memberships" do
    field :role, :string, default: "member"

    belongs_to :user, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :tenant_id, :role])
    |> validate_required([:user_id, :tenant_id, :role])
    |> validate_inclusion(:role, ~w(admin member))
    |> unique_constraint([:user_id, :tenant_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tenant_id)
  end
end
