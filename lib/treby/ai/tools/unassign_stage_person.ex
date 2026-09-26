defmodule Treby.AI.Tools.UnassignStagePerson do
  @moduledoc "Destructive tool: unassign an advancer, examiner or reviewer from a stage."

  alias Treby.AI.Tools

  @roles ~w(advancer examiner reviewer)

  def name, do: "unassign_stage_person"

  def description, do: "Remove a team member's assignment from a pipeline stage."

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
        {:ok, _} = unassign(stage, args["role"], args["user_id"])
        {:ok, %{"stage_id" => stage.id, "user_id" => args["user_id"], "role" => args["role"]}}
      else
        {:error, "stage not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "stage not found"}
  end

  defp unassign(stage, "advancer", user_id), do: Treby.Pipeline.remove_advancer(stage, user_id)
  defp unassign(stage, "examiner", user_id), do: Treby.Pipeline.remove_examiner(stage, user_id)
  defp unassign(stage, "reviewer", user_id), do: Treby.Pipeline.remove_reviewer(stage, user_id)
end
