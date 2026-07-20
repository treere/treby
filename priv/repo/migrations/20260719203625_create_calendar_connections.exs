defmodule Treby.Repo.Migrations.CreateCalendarConnections do
  use Ecto.Migration

  def change do
    create table(:calendar_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider, :string, null: false, default: "google"
      add :access_token, :binary
      add :refresh_token, :binary
      add :token_expires_at, :utc_datetime
      add :google_email, :string
      add :calendar_id, :string
      add :connected_at, :utc_datetime
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:calendar_connections, [:tenant_id, :user_id])
    create index(:calendar_connections, [:user_id])
    create index(:calendar_connections, [:tenant_id])
  end
end
