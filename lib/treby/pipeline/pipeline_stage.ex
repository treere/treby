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
    field :min_examiners, :integer, default: 1

    belongs_to :pipeline, Treby.Pipeline.Pipeline
    belongs_to :scorecard_template, Treby.Scorecards.ScorecardTemplate

    has_many :examiner_assignments, Treby.Pipeline.StageExaminer
    has_many :examiners, through: [:examiner_assignments, :user]

    has_many :reviewer_assignments, Treby.Pipeline.StageReviewer
    has_many :reviewers, through: [:reviewer_assignments, :user]

    has_many :advancer_assignments, Treby.Pipeline.StageAdvancer
    has_many :advancers, through: [:advancer_assignments, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pipeline_stage, attrs) do
    pipeline_stage
    |> cast(attrs, [
      :name,
      :position,
      :color,
      :pipeline_id,
      :stage_type,
      :min_examiners,
      :scorecard_template_id
    ])
    |> validate_required([:name, :position])
  end
end
