defmodule Treby.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Bcrypt

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :name, :string
    field :role, :string, default: "member"
    field :locale, :string, default: "en"
    field :onboarding_checklist_dismissed, :boolean, default: false

    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :memberships, Treby.Memberships.Membership

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :name, :role])
    |> validate_required([:email, :password, :name])
    |> normalize_email()
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 6, message: "must be at least 6 characters")
    |> unique_constraint([:tenant_id, :email])
    |> unique_constraint(:email, name: :users_email_unique_lower_index)
    |> hash_password()
  end

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(email))
    end
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  def locale_changeset(user, attrs) do
    user
    |> cast(attrs, [:locale])
    |> validate_inclusion(:locale, ~w(en it))
  end

  def dismiss_onboarding_changeset(user) do
    change(user, %{onboarding_checklist_dismissed: true})
  end
end
