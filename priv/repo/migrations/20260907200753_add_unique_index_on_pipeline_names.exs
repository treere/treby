defmodule Treby.Repo.Migrations.AddUniqueIndexOnPipelineNames do
  use Ecto.Migration

  def change do
    create unique_index(:pipelines, [:tenant_id, :name])
  end
end
