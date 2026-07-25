defmodule Treby.Repo.Migrations.CreateEmailMessages do
  use Ecto.Migration

  def change do
    create table(:email_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :direction, :string, null: false
      add :from_address, :string, null: false
      add :to_address, :string, null: false
      add :subject, :string
      add :body, :text, null: false
      add :html_body, :text
      add :sent_at, :utc_datetime
      add :received_at, :utc_datetime

      add :thread_id,
          references(:email_threads, type: :binary_id, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create index(:email_messages, [:thread_id])
    create index(:email_messages, [:thread_id, :inserted_at])
  end
end
