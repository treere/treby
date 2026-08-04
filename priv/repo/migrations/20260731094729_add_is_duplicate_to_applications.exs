defmodule Treby.Repo.Migrations.AddIsDuplicateToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :is_duplicate, :boolean, null: false, default: false
    end

    create index(:applications, [:candidate_id, :job_id])
  end
end
