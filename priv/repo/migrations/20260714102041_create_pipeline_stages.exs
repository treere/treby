defmodule Treby.Repo.Migrations.CreatePipelineStages do
  use Ecto.Migration

  def change do
    create table(:pipeline_stages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :position, :integer, null: false, default: 0
      add :color, :string, default: "#3b82f6"
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:pipeline_stages, [:tenant_id])
    create index(:pipeline_stages, [:tenant_id, :position])
  end
end
