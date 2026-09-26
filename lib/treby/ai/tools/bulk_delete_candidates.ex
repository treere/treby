defmodule Treby.AI.Tools.BulkDeleteCandidates do
  @moduledoc "Destructive tool: delete the candidates of many applications (admin)."

  alias Treby.AI.Tools

  def name, do: "bulk_delete_candidates"

  def description,
    do: "Delete the candidates behind multiple applications (applications are removed too)."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_ids" => %{"type" => "array", "items" => %{"type" => "string"}}
      },
      "required" => ["application_ids"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      {:ok, count} =
        Treby.BulkOperations.bulk_delete_candidates(args["application_ids"], ctx[:tenant_id])

      {:ok, %{"deleted" => count}}
    end
  end
end
