defmodule Treby.Activities.ActivityLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "activity_log" do
    field :action, :string
    field :entity_type, :string
    field :entity_id, :binary_id
    field :metadata, :map, default: %{}

    belongs_to :actor, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(activity_log, attrs) do
    activity_log
    |> cast(attrs, [:action, :actor_id, :entity_type, :entity_id, :metadata, :tenant_id])
    |> validate_required([:action, :entity_type, :entity_id, :tenant_id])
  end
end
