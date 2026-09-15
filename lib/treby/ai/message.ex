defmodule Treby.AI.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "ai_messages" do
    field :role, :string
    field :content, :string
    field :tool_calls, :map, default: %{}

    belongs_to :conversation, Treby.AI.Conversation
    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :tool_runs, Treby.AI.ToolRun

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :tenant_id, :role, :content, :tool_calls])
    |> validate_required([:conversation_id, :tenant_id, :role])
  end
end
