defmodule Treby.AI.Tools.CreateCalendarEvent do
  @moduledoc "Destructive tool: create a calendar event with a video link."

  alias Treby.AI.Tools

  def name, do: "create_calendar_event"

  def description,
    do: "Create an event on the current user's calendar with a video conference link."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "provider" => %{"type" => "string", "enum" => ["google", "treby"]},
        "summary" => %{"type" => "string"},
        "description" => %{"type" => "string"},
        "start_at" => %{"type" => "string", "description" => "ISO8601 UTC"},
        "end_at" => %{"type" => "string", "description" => "ISO8601 UTC"},
        "timezone" => %{"type" => "string"},
        "attendee_emails" => %{"type" => "array", "items" => %{"type" => "string"}}
      },
      "required" => ["provider", "summary", "start_at", "end_at"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx),
         {:ok, start_at} <- parse_datetime(args["start_at"]),
         {:ok, end_at} <- parse_datetime(args["end_at"]) do
      params = %{
        summary: args["summary"],
        description: args["description"],
        start_at: start_at,
        end_at: end_at,
        timezone: args["timezone"] || "UTC"
      }

      user_id = Tools.actor_id(ctx)

      case Treby.Calendar.create_event_with_meet(
             user_id,
             args["provider"],
             params,
             args["attendee_emails"] || []
           ) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, inspect(reason)}
      end
    end
  end

  defp parse_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, "invalid datetime; use ISO8601 UTC"}
    end
  end
end
