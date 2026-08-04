defmodule Treby.Repo.Migrations.AddMergedIntoToCandidates do
  use Ecto.Migration

  def change do
    alter table(:candidates) do
      add :merged_into_id, references(:candidates, type: :binary_id, on_delete: :nilify_all)
      add :merged_at, :utc_datetime
    end

    create index(:candidates, [:merged_into_id])
  end
end
