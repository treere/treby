defmodule Treby.Repo.Migrations.CreateScheduledEmails do
  use Ecto.Migration

  def change do
    create table(:scheduled_emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :status, :string, null: false, default: "scheduled"
      add :scheduled_at, :utc_datetime, null: false
      add :send_at, :utc_datetime, null: false
      add :jitter_minutes, :integer, default: 0

      add :to_address, :string, null: false
      add :from_address, :string, null: false
      add :subject, :string, null: false
      add :body, :text
      add :html_body, :text

      add :email_type, :string, null: false
      add :reference_type, :string
      add :reference_id, :binary_id

      add :thread_id, references(:email_threads, type: :binary_id, on_delete: :nilify_all)
      add :email_message_id, references(:email_messages, type: :binary_id, on_delete: :nilify_all)

      add :sent_at, :utc_datetime
      add :failed_at, :utc_datetime
      add :error_reason, :text
      add :retry_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:scheduled_emails, [:tenant_id])
    create index(:scheduled_emails, [:status])
    create index(:scheduled_emails, [:send_at])
    create index(:scheduled_emails, [:thread_id])
    create index(:scheduled_emails, [:email_message_id])
  end
end
