defmodule Treby.Repo.Migrations.AlterPipelineStagesForPipelines do
  use Ecto.Migration

  def change do
    alter table(:pipeline_stages) do
      add :pipeline_id, references(:pipelines, type: :binary_id, on_delete: :delete_all)
      add :stage_type, :string
    end

    create index(:pipeline_stages, [:pipeline_id])
  end
end
