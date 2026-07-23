defmodule Treby.Repo.Migrations.CreateActivityLog do
  use Ecto.Migration

  def change do
    create table(:activity_log, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false
      add :metadata, :map, default: %{}
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:activity_log, [:tenant_id])
    create index(:activity_log, [:entity_type, :entity_id])
    create index(:activity_log, [:actor_id])
    create index(:activity_log, [:inserted_at])
  end
end
