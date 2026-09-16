defmodule Treby.AI.Tools.AddPipelineStage do
  @moduledoc "Destructive tool: add a pipeline stage."

  alias Treby.AI.Tools

  def name, do: "add_pipeline_stage"

  def description,
    do: "Add a stage to a pipeline (defaults to the workspace default pipeline)."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "stage_type" => %{
          "type" => "string",
          "enum" => ["new", "screening", "interview", "offer", "hired", "rejected"]
        },
        "pipeline_id" => %{
          "type" => "string",
          "description" => "Optional; defaults to workspace pipeline"
        },
        "color" => %{"type" => "string", "description" => "Hex color (optional)"}
      },
      "required" => ["name"]
    }
  end

  def run(args, ctx) do
    pipeline_id = args["pipeline_id"] || Treby.Pipeline.default_pipeline_id(ctx[:tenant_id])

    attrs = %{
      "name" => args["name"],
      "stage_type" => args["stage_type"],
      "pipeline_id" => pipeline_id,
      "position" => 0,
      "color" => args["color"]
    }

    case Treby.Pipeline.create_pipeline_stage(attrs, ctx[:user]) do
      {:ok, stage} -> {:ok, %{"id" => stage.id, "name" => stage.name}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
