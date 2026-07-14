defmodule Treby.Pipeline.PipelineStage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pipeline_stages" do
    field :name, :string
    field :position, :integer, default: 0
    field :color, :string, default: "#3b82f6"

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pipeline_stage, attrs) do
    pipeline_stage
    |> cast(attrs, [:name, :position, :color, :tenant_id])
    |> validate_required([:name, :position, :tenant_id])
  end
end
