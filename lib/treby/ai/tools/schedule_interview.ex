defmodule Treby.AI.Tools.ScheduleInterview do
  @moduledoc "Destructive tool: schedule an interview."

  alias Treby.AI.Tools

  def name, do: "schedule_interview"

  def description, do: "Schedule an interview for an application and assign examiners."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_id" => %{"type" => "string"},
        "start_at_utc" => %{"type" => "string", "description" => "ISO8601 UTC"},
        "end_at_utc" => %{"type" => "string", "description" => "ISO8601 UTC"},
        "duration_minutes" => %{"type" => "integer"},
        "notes" => %{"type" => "string"},
        "examiner_ids" => %{
          "type" => "array",
          "items" => %{"type" => "string"},
          "description" => "User ids to assign as examiners"
        }
      },
      "required" => ["application_id", "start_at_utc", "end_at_utc", "duration_minutes"]
    }
  end

  def summary(args) do
    %{
      title: "Schedule interview",
      fields: [
        {"Application", args["application_id"]},
        {"Start (UTC)", args["start_at_utc"]},
        {"End (UTC)", args["end_at_utc"]},
        {"Duration (min)", args["duration_minutes"]},
        {"Examiners", args["examiner_ids"]},
        {"Notes", args["notes"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      actor = Tools.actor(ctx)

      attrs = %{
        "tenant_id" => ctx[:tenant_id],
        "application_id" => args["application_id"],
        "start_at_utc" => args["start_at_utc"],
        "end_at_utc" => args["end_at_utc"],
        "duration_minutes" => args["duration_minutes"],
        "notes" => args["notes"],
        "scheduled_by_id" => Treby.Authorization.Actor.id(actor),
        "examiner_ids" => args["examiner_ids"] || []
      }

      case Treby.Interviews.schedule_interview(attrs) do
        {:ok, event} -> {:ok, %{"id" => event.id, "status" => event.status}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
