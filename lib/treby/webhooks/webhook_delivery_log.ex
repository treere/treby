defmodule Treby.Webhooks.WebhookDeliveryLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_delivery_logs" do
    field :action, :string
    field :payload, :map, default: %{}
    field :status, :string
    field :attempts, :integer, default: 0
    field :last_response, :string

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :subscription, Treby.Webhooks.WebhookSubscription

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [
      :tenant_id,
      :subscription_id,
      :action,
      :payload,
      :status,
      :attempts,
      :last_response
    ])
    |> validate_required([:tenant_id, :subscription_id, :action, :payload, :status])
  end
end
