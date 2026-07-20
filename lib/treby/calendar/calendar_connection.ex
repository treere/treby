defmodule Treby.Calendar.CalendarConnection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "calendar_connections" do
    field :provider, :string, default: "google"
    field :access_token, Treby.Encrypted.Binary
    field :refresh_token, Treby.Encrypted.Binary
    field :token_expires_at, :utc_datetime
    field :google_email, :string
    field :calendar_id, :string
    field :connected_at, :utc_datetime

    belongs_to :user, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [
      :provider,
      :access_token,
      :refresh_token,
      :token_expires_at,
      :google_email,
      :calendar_id,
      :connected_at,
      :user_id,
      :tenant_id
    ])
    |> validate_required([:provider, :user_id, :tenant_id])
    |> unique_constraint([:tenant_id, :user_id])
  end
end
