defmodule Treby.Repo.Migrations.CreateEmailThreads do
  use Ecto.Migration

  def change do
    create table(:email_threads, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string, null: false

      add :candidate_id,
          references(:candidates, type: :binary_id, on_delete: :delete_all),
          null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :last_message_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:email_threads, [:candidate_id])
    create index(:email_threads, [:tenant_id])
    create index(:email_threads, [:candidate_id, :last_message_at])
  end
end
