defmodule Treby.Repo.Migrations.CreateWebhookSubscriptions do
  use Ecto.Migration

  def change do
    create table(:webhook_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :target_url, :text, null: false
      add :events, {:array, :string}, null: false, default: []
      add :secret, :binary, null: false
      add :active, :boolean, null: false, default: true
      add :description, :text, null: false, default: ""

      timestamps(type: :utc_datetime)
    end

    create index(:webhook_subscriptions, [:tenant_id])
  end
end
