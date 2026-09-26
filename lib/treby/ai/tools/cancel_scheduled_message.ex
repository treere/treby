defmodule Treby.AI.Tools.CancelScheduledMessage do
  @moduledoc "Destructive tool: cancel a scheduled message."

  alias Treby.AI.Tools

  def name, do: "cancel_scheduled_message"

  def description, do: "Cancel a scheduled message."

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
        case Treby.ScheduledMessages.cancel(message) do
          {:ok, cancelled} -> {:ok, %{"id" => cancelled.id, "status" => cancelled.status}}
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
