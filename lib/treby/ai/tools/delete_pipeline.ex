defmodule Treby.AI.Tools.DeletePipeline do
  @moduledoc "Destructive tool: delete a pipeline."

  alias Treby.AI.Tools

  def name, do: "delete_pipeline"

  def description, do: "Delete a pipeline from the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"pipeline_id" => %{"type" => "string"}},
      "required" => ["pipeline_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete pipeline",
      fields: [
        {"Pipeline", args["pipeline_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      pipeline = Treby.Pipeline.get_pipeline(args["pipeline_id"])

      if pipeline && pipeline.tenant_id == ctx[:tenant_id] do
        case Treby.Pipeline.delete_pipeline(pipeline) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "pipeline not found"}
      end
    end
  end
end
