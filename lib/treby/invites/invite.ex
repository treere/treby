defmodule Treby.Invites.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "invites" do
    field :email, :string
    field :role, :string, default: "member"
    field :token, :string
    field :accepted_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :role, :token, :expires_at, :tenant_id])
    |> validate_required([:email, :role, :token, :expires_at, :tenant_id])
    |> validate_format(:email, ~r/@/)
    |> validate_inclusion(:role, ~w(admin member))
    |> unique_constraint([:tenant_id, :email])
    |> unique_constraint(:token)
  end
end
