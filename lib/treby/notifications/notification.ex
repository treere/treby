defmodule Treby.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :type, :string
    field :title, :string
    field :body, :string
    field :link, :string
    field :read_at, :utc_datetime

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :recipient, Treby.Accounts.User, foreign_key: :recipient_id
    belongs_to :actor, Treby.Accounts.User, foreign_key: :actor_id

    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:tenant_id, :recipient_id, :actor_id, :type, :title, :body, :link, :read_at])
    |> validate_required([:tenant_id, :recipient_id, :type, :title])
  end
end
