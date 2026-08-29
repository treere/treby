defmodule TrebyWeb.Registration do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :company_name, :string
    field :name, :string
    field :email, :string
    field :password, :string
    field :password_confirmation, :string
    field :tos_accepted, :boolean, default: false
  end

  @doc """
  Validates the email before a verification code is sent.
  """
  def email_changeset(registration, attrs) do
    registration
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  end

  def changeset(registration, attrs) do
    registration
    |> cast(attrs, [
      :company_name,
      :name,
      :email,
      :password,
      :password_confirmation,
      :tos_accepted
    ])
    |> validate_required([:company_name, :name, :email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 6, message: "must be at least 6 characters")
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_acceptance(:tos_accepted, message: "must be accepted")
  end
end
