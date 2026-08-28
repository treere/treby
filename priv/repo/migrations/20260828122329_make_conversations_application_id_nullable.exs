defmodule Treby.Repo.Migrations.MakeConversationsApplicationIdNullable do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      modify :application_id, :binary_id, null: true
    end
  end
end
