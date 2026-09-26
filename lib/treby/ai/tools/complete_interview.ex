defmodule Treby.AI.Tools.CompleteInterview do
  @moduledoc "Destructive tool: mark an interview completed."

  alias Treby.AI.Tools

  def name, do: "complete_interview"

  def description, do: "Mark a scheduled interview as completed."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"interview_id" => %{"type" => "string"}},
      "required" => ["interview_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      event = Treby.Interviews.get_event!(args["interview_id"])

      if event.tenant_id == ctx[:tenant_id] do
        case Treby.Interviews.complete_interview(event, Tools.actor(ctx)) do
          {:ok, completed} -> {:ok, %{"id" => completed.id, "status" => completed.status}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "interview not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "interview not found"}
  end
end
