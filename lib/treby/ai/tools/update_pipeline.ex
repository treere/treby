defmodule Treby.AI.Tools.UpdatePipeline do
  @moduledoc "Destructive tool: rename a pipeline."

  alias Treby.AI.Tools

  def name, do: "update_pipeline"

  def description, do: "Rename a pipeline in the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "pipeline_id" => %{"type" => "string"},
        "name" => %{"type" => "string"}
      },
      "required" => ["pipeline_id", "name"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      pipeline = Treby.Pipeline.get_pipeline(args["pipeline_id"])

      if pipeline && pipeline.tenant_id == ctx[:tenant_id] do
        case Treby.Pipeline.update_pipeline(pipeline, %{"name" => args["name"]}) do
          {:ok, updated} -> {:ok, %{"id" => updated.id, "name" => updated.name}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "pipeline not found"}
      end
    end
  end
end
