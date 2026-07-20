defmodule Treby.Repo.Migrations.CreateBookingTokens do
  use Ecto.Migration

  def change do
    create table(:booking_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :used_at, :utc_datetime

      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all),
        null: false

      add :interviewer_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:booking_tokens, [:token])
    create index(:booking_tokens, [:application_id])
    create index(:booking_tokens, [:tenant_id])
  end
end
