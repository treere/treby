defmodule Treby.AI.Tools.SubmitScorecard do
  @moduledoc "Destructive tool: submit the current user's scorecard for an interview."

  alias Treby.AI.Tools

  def name, do: "submit_scorecard"

  def description, do: "Submit or update your scorecard for an interview."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "interview_id" => %{"type" => "string"},
        "scores" => %{"type" => "object", "description" => "Map of criterion => score"},
        "recommendation" => %{"type" => "string", "description" => "Overall recommendation"},
        "notes" => %{"type" => "string"}
      },
      "required" => ["interview_id"]
    }
  end

  def summary(args) do
    %{
      title: "Submit scorecard",
      fields: [
        {"Interview", args["interview_id"]},
        {"Recommendation", args["recommendation"]},
        {"Scores", args["scores"]},
        {"Notes", args["notes"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      interviewer_id = Tools.actor(ctx).id

      attrs =
        %{}
        |> maybe_put("scores", args["scores"])
        |> maybe_put("recommendation", args["recommendation"])
        |> maybe_put("notes", args["notes"])

      case Treby.Scorecards.submit_scorecard(args["interview_id"], interviewer_id, attrs) do
        {:ok, scorecard} -> {:ok, %{"id" => scorecard.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
