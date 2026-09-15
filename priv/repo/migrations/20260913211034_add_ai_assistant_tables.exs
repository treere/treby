defmodule Treby.Repo.Migrations.AddAiAssistantTables do
  use Ecto.Migration

  def change do
    create table(:ai_conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :title, :string
      add :status, :string, null: false, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:ai_conversations, [:tenant_id, :user_id, :status])
    create index(:ai_conversations, [:tenant_id])

    create table(:ai_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :conversation_id,
          references(:ai_conversations, type: :binary_id, on_delete: :delete_all), null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :content, :text
      add :tool_calls, :map, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:ai_messages, [:conversation_id, :inserted_at])
    create index(:ai_messages, [:tenant_id])

    create table(:ai_tool_runs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :message_id, references(:ai_messages, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :tool, :string, null: false
      add :args, :map, default: %{}
      add :status, :string, null: false, default: "pending_confirm"
      add :result, :map

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:ai_tool_runs, [:message_id])
    create index(:ai_tool_runs, [:tenant_id])
  end
end
