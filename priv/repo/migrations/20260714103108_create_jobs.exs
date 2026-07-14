defmodule Treby.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :salary_range, :string
      add :status, :string, null: false, default: "open"
      add :custom_fields, :map, default: %{}
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:jobs, [:tenant_id])
    create index(:jobs, [:tenant_id, :status])
  end
end
