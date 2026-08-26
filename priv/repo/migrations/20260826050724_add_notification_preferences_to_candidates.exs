defmodule Treby.Repo.Migrations.AddNotificationPreferencesToCandidates do
  use Ecto.Migration

  def change do
    alter table(:candidates) do
      add :notification_preferences, :map, default: %{}
    end
  end
end
