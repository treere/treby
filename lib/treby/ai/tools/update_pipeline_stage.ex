defmodule Treby.AI.Tools.UpdatePipelineStage do
  @moduledoc "Destructive tool: update a pipeline stage."

  alias Treby.AI.Tools

  @fields ~w(name position color stage_type min_examiners)

  def name, do: "update_pipeline_stage"

  def description, do: "Update a pipeline stage (name, position, color, type, min examiners)."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "stage_id" => %{"type" => "string"},
        "name" => %{"type" => "string"},
        "position" => %{"type" => "integer"},
        "color" => %{"type" => "string"},
        "stage_type" => %{
          "type" => "string",
          "enum" => ["new", "screening", "interview", "offer", "hired", "rejected"]
        },
        "min_examiners" => %{"type" => "integer"}
      },
      "required" => ["stage_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      stage = Treby.Pipeline.get_pipeline_stage!(args["stage_id"])

      if tenant_owns_stage?(stage, ctx[:tenant_id]) do
        case Treby.Pipeline.update_pipeline_stage(
               stage,
               Map.take(args, @fields),
               Tools.actor(ctx)
             ) do
          {:ok, updated} -> {:ok, %{"id" => updated.id, "name" => updated.name}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "stage not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "stage not found"}
  end

  defp tenant_owns_stage?(stage, tenant_id) do
    match?(%{tenant_id: ^tenant_id}, Treby.Pipeline.get_pipeline(stage.pipeline_id))
  end
end
