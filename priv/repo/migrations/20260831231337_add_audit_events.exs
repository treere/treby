defmodule Treby.Repo.Migrations.AddAuditEvents do
  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :actor_type, :string, null: false, default: "user"
      add :action, :string, null: false
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false
      add :metadata, :map, default: %{}
      add :ip, :string
      add :user_agent, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_events, [:tenant_id])
    create index(:audit_events, [:tenant_id, :inserted_at])
    create index(:audit_events, [:entity_type, :entity_id])
    create index(:audit_events, [:actor_id])
    create index(:audit_events, [:action])
    create index(:audit_events, [:inserted_at])
  end
end
