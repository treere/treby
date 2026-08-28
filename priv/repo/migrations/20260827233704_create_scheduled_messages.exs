defmodule Treby.Repo.Migrations.CreateScheduledMessages do
  use Ecto.Migration

  def change do
    create table(:scheduled_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sender_type, :string, null: false
      add :sender_id, :binary_id
      add :body, :text, null: false
      add :message_type, :string, null: false, default: "text"
      add :metadata, :map, default: %{}
      add :send_at, :utc_datetime, null: false
      add :status, :string, null: false, default: "scheduled"
      add :sent_at, :utc_datetime
      add :failed_at, :utc_datetime
      add :error_reason, :string
      add :retry_count, :integer, null: false, default: 0
      add :created_by_id, :binary_id

      add :conversation_id,
          references(:conversations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scheduled_messages, [:conversation_id])
    create index(:scheduled_messages, [:tenant_id])
    create index(:scheduled_messages, [:status])
    create index(:scheduled_messages, [:send_at])
  end
end
