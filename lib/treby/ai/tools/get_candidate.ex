defmodule Treby.AI.Tools.GetCandidate do
  @moduledoc "Read-only tool: fetch one candidate by id."

  def name, do: "get_candidate"

  def description, do: "Get the full details of a single candidate by id."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "string", "description" => "Candidate id"}
      },
      "required" => ["id"]
    }
  end

  def run(args, ctx) do
    case Treby.Candidates.get_candidate(ctx[:tenant_id], args["id"]) do
      nil -> {:error, "candidate not found"}
      candidate -> {:ok, candidate}
    end
  end
end
