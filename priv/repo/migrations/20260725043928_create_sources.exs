defmodule Treby.Repo.Migrations.CreateSources do
  use Ecto.Migration

  def change do
    create table(:sources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :is_default, :boolean, default: false, null: false
      add :position, :integer, default: 0, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:sources, [:tenant_id])
    create unique_index(:sources, [:tenant_id, :name])
  end
end
