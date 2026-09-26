defmodule Treby.Memberships.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "memberships" do
    field :role, :string, default: "recruiter"

    belongs_to :user, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :tenant_id, :role])
    |> normalize_legacy_role()
    |> validate_required([:user_id, :tenant_id, :role])
    |> validate_inclusion(:role, ~w(admin recruiter interviewer))
    |> unique_constraint([:user_id, :tenant_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tenant_id)
  end

  # Gracefully migrate the retired "member" role to its replacement.
  defp normalize_legacy_role(changeset) do
    case get_change(changeset, :role) do
      "member" -> put_change(changeset, :role, "recruiter")
      _ -> changeset
    end
  end
end
