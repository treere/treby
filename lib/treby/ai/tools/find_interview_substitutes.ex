defmodule Treby.AI.Tools.FindInterviewSubstitutes do
  @moduledoc "Read-only tool: find substitutes for a cancelled examiner (admin)."

  def name, do: "find_interview_substitutes"

  def description, do: "Suggest substitute examiners for a cancelled interview examiner slot."

  def destructive?, do: false

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "interview_id" => %{"type" => "string"},
        "user_id" => %{"type" => "string", "description" => "Cancelled examiner user id"}
      },
      "required" => ["interview_id", "user_id"]
    }
  end

  def run(args, ctx) do
    event = Treby.Interviews.get_event!(args["interview_id"])

    if event.tenant_id != ctx[:tenant_id] do
      {:error, "interview not found"}
    else
      case Treby.Repo.get_by(Treby.Interviews.EventExaminer,
             interview_event_id: args["interview_id"],
             user_id: args["user_id"]
           ) do
        nil -> {:error, "examiner not found for this interview"}
        examiner -> {:ok, Treby.Interviews.find_substitutes(examiner)}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "interview not found"}
  end
end
