defmodule Treby.AI.Tools.BulkMoveStage do
  @moduledoc "Destructive tool: move many applications to a stage."

  alias Treby.AI.Tools

  def name, do: "bulk_move_stage"

  def description, do: "Move multiple applications to the same pipeline stage at once."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_ids" => %{"type" => "array", "items" => %{"type" => "string"}},
        "stage_id" => %{"type" => "string"}
      },
      "required" => ["application_ids", "stage_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      {count, _} =
        Treby.BulkOperations.bulk_move_stage(
          args["application_ids"],
          args["stage_id"],
          ctx[:tenant_id],
          Tools.actor(ctx)
        )

      {:ok, %{"moved" => count}}
    end
  end
end
