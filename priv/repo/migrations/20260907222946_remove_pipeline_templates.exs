defmodule Treby.Repo.Migrations.RemovePipelineTemplates do
  use Ecto.Migration

  def change do
    execute("DELETE FROM pipelines WHERE is_template = true", "")

    alter table(:pipelines) do
      remove :is_template
    end
  end
end
