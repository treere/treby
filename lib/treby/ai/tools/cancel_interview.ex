defmodule Treby.AI.Tools.CancelInterview do
  @moduledoc "Destructive tool: cancel an interview."

  alias Treby.AI.Tools

  def name, do: "cancel_interview"

  def description, do: "Cancel a scheduled interview."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"interview_id" => %{"type" => "string"}},
      "required" => ["interview_id"]
    }
  end

  def summary(args) do
    %{
      title: "Cancel interview",
      fields: [
        {"Interview", args["interview_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      event = Treby.Interviews.get_event!(args["interview_id"])

      if event.tenant_id == ctx[:tenant_id] do
        case Treby.Interviews.cancel_interview(event) do
          {:ok, cancelled} -> {:ok, %{"id" => cancelled.id, "status" => cancelled.status}}
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
