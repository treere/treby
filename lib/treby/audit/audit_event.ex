defmodule Treby.Audit.AuditEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @actor_types ~w(user candidate system)

  schema "audit_events" do
    field :actor_type, :string, default: "user"
    field :action, :string
    field :entity_type, :string
    field :entity_id, :binary_id
    field :metadata, :map, default: %{}
    field :ip, :string
    field :user_agent, :string

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :actor, Treby.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(audit_event, attrs) do
    audit_event
    |> cast(attrs, [
      :tenant_id,
      :actor_id,
      :actor_type,
      :action,
      :entity_type,
      :entity_id,
      :metadata,
      :ip,
      :user_agent
    ])
    |> validate_required([:tenant_id, :actor_type, :action, :entity_type, :entity_id])
    |> validate_inclusion(:actor_type, @actor_types)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:actor_id)
  end
end
