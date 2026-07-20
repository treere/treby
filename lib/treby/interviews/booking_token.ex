defmodule Treby.Interviews.BookingToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "booking_tokens" do
    field :token, :string
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime

    belongs_to :application, Treby.Pipeline.Application
    belongs_to :interviewer, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :expires_at, :used_at, :application_id, :interviewer_id, :tenant_id])
    |> validate_required([:token, :expires_at, :application_id, :tenant_id])
    |> unique_constraint(:token)
  end
end
