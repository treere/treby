defmodule Treby.Pipeline.PipelineStage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pipeline_stages" do
    field :name, :string
    field :position, :integer, default: 0
    field :color, :string, default: "#3b82f6"
    field :stage_type, :string

    belongs_to :pipeline, Treby.Pipeline.Pipeline

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pipeline_stage, attrs) do
    pipeline_stage
    |> cast(attrs, [:name, :position, :color, :pipeline_id, :stage_type])
    |> validate_required([:name, :position])
  end
end
