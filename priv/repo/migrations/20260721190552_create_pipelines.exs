defmodule Treby.Repo.Migrations.CreatePipelines do
  use Ecto.Migration

  def change do
    create table(:pipelines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :is_default, :boolean, default: false, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:pipelines, [:tenant_id])
    create index(:pipelines, [:tenant_id, :is_default])
  end
end
