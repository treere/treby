defmodule Treby.Repo.Migrations.AddVisibleToJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :visible, :boolean, default: true, null: false
    end
  end
end
