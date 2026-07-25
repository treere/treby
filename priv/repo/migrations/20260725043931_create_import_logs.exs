defmodule Treby.Repo.Migrations.CreateImportLogs do
  use Ecto.Migration

  def change do
    create table(:import_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_name, :string, null: false
      add :imported_count, :integer, default: 0, null: false
      add :skipped_count, :integer, default: 0, null: false
      add :error_count, :integer, default: 0, null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:import_logs, [:tenant_id])
    create index(:import_logs, [:user_id])
  end
end
