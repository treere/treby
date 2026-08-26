defmodule Treby.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sender_type, :string, null: false
      add :sender_id, :binary_id
      add :body, :text, null: false
      add :message_type, :string, null: false, default: "text"
      add :metadata, :map, default: %{}

      add :conversation_id, references(:conversations, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_type])
  end
end
