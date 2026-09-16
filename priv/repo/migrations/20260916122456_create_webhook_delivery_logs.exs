defmodule Treby.Repo.Migrations.CreateWebhookDeliveryLogs do
  use Ecto.Migration

  def change do
    create table(:webhook_delivery_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      add :subscription_id,
          references(:webhook_subscriptions, type: :binary_id, on_delete: :delete_all),
          null: false

      add :action, :string, null: false
      add :payload, :map, null: false
      add :status, :string, null: false
      add :attempts, :integer, null: false, default: 0
      add :last_response, :text

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:webhook_delivery_logs, [:tenant_id])
    create index(:webhook_delivery_logs, [:subscription_id])
    create index(:webhook_delivery_logs, [:action])
    create index(:webhook_delivery_logs, [:inserted_at])
  end
end
