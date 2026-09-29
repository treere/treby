defmodule Treby.AI.Tools.RescheduleScheduledMessage do
  @moduledoc "Destructive tool: reschedule a scheduled message."

  alias Treby.AI.Tools

  def name, do: "reschedule_scheduled_message"

  def description, do: "Change the delivery time of a scheduled message."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "string"},
        "send_at" => %{"type" => "string", "description" => "ISO8601 UTC"}
      },
      "required" => ["id", "send_at"]
    }
  end

  def summary(args) do
    %{
      title: "Reschedule message",
      fields: [
        {"Id", args["id"]},
        {"Send at", args["send_at"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx),
         {:ok, send_at, _} <- DateTime.from_iso8601(args["send_at"]) do
      message = Treby.ScheduledMessages.get_scheduled_message!(args["id"])

      if message.tenant_id == ctx[:tenant_id] do
        with {:ok, edited} <- Treby.ScheduledMessages.edit(message, %{"send_at" => send_at}),
             {:ok, rescheduled} <- Treby.ScheduledMessages.reschedule_delivery!(edited) do
          {:ok, %{"id" => rescheduled.id, "send_at" => rescheduled.send_at}}
        else
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "message not found"}
      end
    else
      {:error, :invalid_format} -> {:error, "invalid send_at; use an ISO8601 UTC datetime"}
      {:error, :invalid_date} -> {:error, "invalid send_at; use an ISO8601 UTC datetime"}
    end
  rescue
    Ecto.NoResultsError -> {:error, "message not found"}
  end
end
