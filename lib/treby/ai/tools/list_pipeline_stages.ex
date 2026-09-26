defmodule Treby.AI.Tools.ListPipelineStages do
  @moduledoc "Read-only tool: list pipeline stages."

  def name, do: "list_pipeline_stages"

  def description, do: "List the stages of a pipeline, or of the workspace default pipeline."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "pipeline_id" => %{
          "type" => "string",
          "description" => "Optional; defaults to the workspace pipeline"
        }
      }
    }
  end

  def run(args, ctx) do
    pipeline_id = args["pipeline_id"] || Treby.Pipeline.default_pipeline_id(ctx[:tenant_id])

    stages =
      pipeline_id
      |> Treby.Pipeline.list_pipeline_stages()
      |> Enum.map(&%{"id" => &1.id, "name" => &1.name, "stage_type" => &1.stage_type})

    {:ok, stages}
  end
end
