defmodule Treby.AI.Tools.RetryScheduledMessage do
  @moduledoc "Destructive tool: retry a failed scheduled message."

  alias Treby.AI.Tools

  def name, do: "retry_scheduled_message"

  def description, do: "Retry delivering a failed scheduled message."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"id" => %{"type" => "string"}},
      "required" => ["id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      message = Treby.ScheduledMessages.get_scheduled_message!(args["id"])

      if message.tenant_id == ctx[:tenant_id] do
        case Treby.ScheduledMessages.retry_failed(message) do
          {:ok, retried} -> {:ok, %{"id" => retried.id, "status" => retried.status}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "message not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "message not found"}
  end
end
