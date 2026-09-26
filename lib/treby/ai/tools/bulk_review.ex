defmodule Treby.AI.Tools.BulkReview do
  @moduledoc "Destructive tool: mark many applications reviewed or unreviewed."

  alias Treby.AI.Tools

  def name, do: "bulk_review"

  def description, do: "Mark multiple applications as reviewed or unreviewed at once."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_ids" => %{"type" => "array", "items" => %{"type" => "string"}},
        "reviewed" => %{
          "type" => "boolean",
          "description" => "true for reviewed, false for unreviewed"
        }
      },
      "required" => ["application_ids", "reviewed"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      {count, _} =
        if args["reviewed"],
          do: Treby.BulkOperations.bulk_mark_reviewed(args["application_ids"], ctx[:tenant_id]),
          else:
            Treby.BulkOperations.bulk_mark_unreviewed(args["application_ids"], ctx[:tenant_id])

      {:ok, %{"updated" => count}}
    end
  end
end
