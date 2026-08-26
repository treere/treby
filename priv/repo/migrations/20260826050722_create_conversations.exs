defmodule Treby.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subject, :string
      add :context, :string, null: false, default: "general"
      add :status, :string, null: false, default: "open"
      add :last_message_at, :utc_datetime

      add :candidate_id, references(:candidates, type: :binary_id, on_delete: :delete_all),
        null: false

      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:conversations, [:candidate_id])
    create index(:conversations, [:application_id])
    create index(:conversations, [:tenant_id])
    create index(:conversations, [:status])
  end
end
