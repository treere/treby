defmodule Treby.Repo.Migrations.AddPipelineIdToJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :pipeline_id, references(:pipelines, type: :binary_id, on_delete: :nilify_all)
    end

    create index(:jobs, [:pipeline_id])
  end
end
