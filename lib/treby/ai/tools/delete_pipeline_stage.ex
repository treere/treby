defmodule Treby.AI.Tools.DeletePipelineStage do
  @moduledoc "Destructive tool: delete a pipeline stage."

  alias Treby.AI.Tools

  def name, do: "delete_pipeline_stage"

  def description, do: "Delete a pipeline stage from the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"stage_id" => %{"type" => "string"}},
      "required" => ["stage_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete pipeline stage",
      fields: [
        {"Stage", args["stage_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      stage = Treby.Pipeline.get_pipeline_stage!(args["stage_id"])
      pipeline = Treby.Pipeline.get_pipeline(stage.pipeline_id)

      if pipeline && pipeline.tenant_id == ctx[:tenant_id] do
        case Treby.Pipeline.delete_pipeline_stage(stage, Tools.actor(ctx)) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "stage not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "stage not found"}
  end
end
