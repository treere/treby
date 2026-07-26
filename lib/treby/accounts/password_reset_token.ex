defmodule Treby.Accounts.PasswordResetToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "password_reset_tokens" do
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime

    belongs_to :user, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token_hash, :expires_at, :used_at, :user_id])
    |> validate_required([:token_hash, :expires_at, :user_id])
    |> unique_constraint(:token_hash)
  end
end
