defmodule Treby.AI.Tools.CandidateCompare do
  @moduledoc "Read-only tool: side-by-side candidate comparison."

  def name, do: "candidate_compare"

  def description, do: "Compare a set of candidates side by side across their profile fields."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "candidate_ids" => %{
          "type" => "array",
          "items" => %{"type" => "string"},
          "description" => "Candidate ids to compare"
        }
      },
      "required" => ["candidate_ids"]
    }
  end

  def run(args, _ctx) do
    {:ok, Treby.Comparison.compare_candidates(args["candidate_ids"])}
  end
end
