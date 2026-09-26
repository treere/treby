defmodule Treby.Invites.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "invites" do
    field :email, :string
    field :role, :string, default: "recruiter"
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
    |> normalize_legacy_role()
    |> validate_required([:email, :role, :token, :expires_at, :tenant_id])
    |> Treby.Emails.validate_format(:email)
    |> validate_inclusion(:role, ~w(admin recruiter interviewer))
    |> unique_constraint([:tenant_id, :email])
    |> unique_constraint(:token)
  end

  # Gracefully migrate the retired "member" role to its replacement.
  defp normalize_legacy_role(changeset) do
    import Ecto.Changeset, only: [get_change: 2, put_change: 3]

    case get_change(changeset, :role) do
      "member" -> put_change(changeset, :role, "recruiter")
      _ -> changeset
    end
  end
end
