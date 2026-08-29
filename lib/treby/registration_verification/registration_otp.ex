defmodule Treby.RegistrationVerification.RegistrationOtp do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "registration_otps" do
    field :email, :string
    field :code, :string
    field :expires_at, :utc_datetime
    field :attempts, :integer, default: 0
    field :used_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(otp, attrs) do
    otp
    |> cast(attrs, [:email, :code, :expires_at, :attempts, :used_at])
    |> validate_required([:email, :code, :expires_at])
  end
end
