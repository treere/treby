defmodule Treby.AI.Tools.ScheduleMessage do
  @moduledoc "Destructive tool: schedule a message to a candidate conversation."

  alias Treby.AI.Tools

  def name, do: "schedule_message"

  def description, do: "Schedule a message to a candidate at a future time (ISO8601 UTC)."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "conversation_id" => %{"type" => "string"},
        "body" => %{"type" => "string"},
        "send_at" => %{"type" => "string", "description" => "ISO8601 UTC datetime"}
      },
      "required" => ["conversation_id", "body", "send_at"]
    }
  end

  def run(args, ctx) do
    case DateTime.from_iso8601(args["send_at"]) do
      {:ok, send_at, _} ->
        attrs = %{
          "conversation_id" => args["conversation_id"],
          "body" => args["body"],
          "send_at" => send_at,
          "sender_type" => "recruiter",
          "tenant_id" => ctx[:tenant_id]
        }

        case Treby.ScheduledMessages.create_scheduled_message(attrs) do
          {:ok, sm} -> {:ok, %{"id" => sm.id, "status" => sm.status}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end

      _ ->
        {:error, "invalid send_at; use an ISO8601 UTC datetime"}
    end
  end
end
