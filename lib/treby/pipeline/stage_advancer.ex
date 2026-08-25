defmodule Treby.Pipeline.StageAdvancer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pipeline_stage_advancers" do
    belongs_to :pipeline_stage, Treby.Pipeline.PipelineStage
    belongs_to :user, Treby.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(advancer, attrs) do
    advancer
    |> cast(attrs, [:pipeline_stage_id, :user_id])
    |> validate_required([:pipeline_stage_id, :user_id])
    |> unique_constraint([:pipeline_stage_id, :user_id])
  end
end
