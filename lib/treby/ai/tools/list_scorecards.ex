defmodule Treby.AI.Tools.ListScorecards do
  @moduledoc "Read-only tool: list scorecards."

  def name, do: "list_scorecards"

  def description, do: "List the scorecards of a candidate or of an interview."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "candidate_id" => %{"type" => "string"},
        "interview_id" => %{"type" => "string"}
      }
    }
  end

  def run(args, ctx) do
    cond do
      args["candidate_id"] ->
        case Treby.Candidates.get_candidate(ctx[:tenant_id], args["candidate_id"]) do
          nil -> {:error, "candidate not found"}
          candidate -> {:ok, Treby.Scorecards.list_scorecards_for_candidate(candidate.id)}
        end

      args["interview_id"] ->
        event = Treby.Interviews.get_event!(args["interview_id"])

        if event.tenant_id == ctx[:tenant_id] do
          {:ok, Treby.Scorecards.list_scorecards_for_interview(event.id)}
        else
          {:error, "interview not found"}
        end

      true ->
        {:error, "provide candidate_id or interview_id"}
    end
  rescue
    Ecto.NoResultsError -> {:error, "not found"}
  end
end
