defmodule Treby.Repo.Migrations.CreateGdprRequests do
  use Ecto.Migration

  def change do
    create table(:gdpr_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :requester_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      add :type, :string, null: false
      add :scope, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :s3_key, :string
      add :expires_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :metadata, :map, null: false, default: %{}
      add :error, :text

      timestamps(type: :utc_datetime)
    end

    create index(:gdpr_requests, [:tenant_id, :status])
    create index(:gdpr_requests, [:expires_at])
    create index(:gdpr_requests, [:tenant_id, :type])

    create unique_index(:gdpr_requests, [:tenant_id, :type, :scope, :requester_id],
             where: "status IN ('pending', 'processing')",
             name: :gdpr_requests_pending_unique
           )
  end
end
