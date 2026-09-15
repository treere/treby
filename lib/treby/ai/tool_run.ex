defmodule Treby.AI.ToolRun do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending_confirm executed rejected failed)

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "ai_tool_runs" do
    field :tool, :string
    field :args, :map, default: %{}
    field :status, :string, default: "pending_confirm"
    field :result, :map

    belongs_to :message, Treby.AI.Message
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(tool_run, attrs) do
    tool_run
    |> cast(attrs, [:message_id, :tenant_id, :tool, :args, :status, :result])
    |> validate_required([:message_id, :tenant_id, :tool])
    |> validate_inclusion(:status, @statuses)
  end
end
