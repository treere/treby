defmodule Treby.Repo.Migrations.AddSessionTokenToAiConversations do
  use Ecto.Migration

  def change do
    alter table(:ai_conversations) do
      add :session_token, :string
    end

    create index(:ai_conversations, [:tenant_id, :user_id, :session_token, :inserted_at])
  end
end
