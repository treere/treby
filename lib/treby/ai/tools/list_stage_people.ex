defmodule Treby.AI.Tools.ListStagePeople do
  @moduledoc "Read-only tool: list advancers, examiners and reviewers of a stage."

  def name, do: "list_stage_people"

  def description, do: "List the advancers, examiners and reviewers assigned to a pipeline stage."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{"stage_id" => %{"type" => "string"}},
      "required" => ["stage_id"]
    }
  end

  def run(args, ctx) do
    stage = Treby.Pipeline.get_pipeline_stage!(args["stage_id"])
    pipeline = Treby.Pipeline.get_pipeline(stage.pipeline_id)

    if pipeline && pipeline.tenant_id == ctx[:tenant_id] do
      {:ok,
       %{
         "advancers" => Enum.map(Treby.Pipeline.list_advancers(stage), &user_summary/1),
         "examiners" => Enum.map(Treby.Pipeline.list_examiners(stage), &user_summary/1),
         "reviewers" => Enum.map(Treby.Pipeline.list_reviewers(stage), &user_summary/1)
       }}
    else
      {:error, "stage not found"}
    end
  rescue
    Ecto.NoResultsError -> {:error, "stage not found"}
  end

  defp user_summary(nil), do: nil
  defp user_summary(%{id: id, name: name}), do: %{"id" => id, "name" => name}
  defp user_summary(other), do: other
end
