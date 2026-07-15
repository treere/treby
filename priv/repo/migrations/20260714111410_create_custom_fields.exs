defmodule Treby.Repo.Migrations.CreateCustomFields do
  use Ecto.Migration

  def change do
    create table(:custom_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :field_type, :string, null: false, default: "text"
      add :applies_to, :string, null: false
      add :options, {:array, :string}, default: []
      add :required, :boolean, default: false
      add :position, :integer, default: 0

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:custom_fields, [:tenant_id])
    create index(:custom_fields, [:tenant_id, :applies_to])
  end
end
