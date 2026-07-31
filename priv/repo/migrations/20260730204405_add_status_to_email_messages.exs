defmodule Treby.Repo.Migrations.AddStatusToEmailMessages do
  use Ecto.Migration

  def change do
    alter table(:email_messages) do
      add :status, :string, default: "sent"
      add :scheduled_at, :utc_datetime

      add :scheduled_email_id,
          references(:scheduled_emails, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:email_messages, [:status])
    create index(:email_messages, [:scheduled_email_id])
  end
end
