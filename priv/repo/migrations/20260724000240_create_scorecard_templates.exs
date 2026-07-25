defmodule Treby.Repo.Migrations.CreateScorecardTemplates do
  use Ecto.Migration

  def change do
    create table(:scorecard_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :criteria, :map, null: false, default: %{}
      add :position, :integer, null: false, default: 0
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scorecard_templates, [:tenant_id])
  end
end
