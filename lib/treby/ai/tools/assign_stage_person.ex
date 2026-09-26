defmodule Treby.AI.Tools.AssignStagePerson do
  @moduledoc "Destructive tool: assign an advancer, examiner or reviewer to a stage."

  alias Treby.AI.Tools

  @roles ~w(advancer examiner reviewer)

  def name, do: "assign_stage_person"

  def description,
    do: "Assign a team member to a pipeline stage as advancer, examiner or reviewer."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "stage_id" => %{"type" => "string"},
        "user_id" => %{"type" => "string"},
        "role" => %{"type" => "string", "enum" => @roles}
      },
      "required" => ["stage_id", "user_id", "role"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      stage = Treby.Pipeline.get_pipeline_stage!(args["stage_id"])
      pipeline = Treby.Pipeline.get_pipeline(stage.pipeline_id)

      if pipeline && pipeline.tenant_id == ctx[:tenant_id] do
        {:ok, _} = assign(stage, args["role"], args["user_id"])
        {:ok, %{"stage_id" => stage.id, "user_id" => args["user_id"], "role" => args["role"]}}
      else
        {:error, "stage not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "stage not found"}
  end

  defp assign(stage, "advancer", user_id), do: Treby.Pipeline.assign_advancer(stage, user_id)
  defp assign(stage, "examiner", user_id), do: Treby.Pipeline.assign_examiner(stage, user_id)
  defp assign(stage, "reviewer", user_id), do: Treby.Pipeline.assign_reviewer(stage, user_id)
end
