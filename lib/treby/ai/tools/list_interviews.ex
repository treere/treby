defmodule Treby.AI.Tools.ListInterviews do
  @moduledoc "Read-only tool: list upcoming interviews."

  def name, do: "list_interviews"

  def description,
    do: "List upcoming interviews for the workspace, or all interviews of an application."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_id" => %{
          "type" => "string",
          "description" => "Optional; filter by application"
        }
      }
    }
  end

  def run(args, ctx) do
    events =
      if args["application_id"] do
        application = Treby.Pipeline.get_application!(ctx[:tenant_id], args["application_id"])
        Treby.Interviews.list_for_application(application.id)
      else
        Treby.Interviews.list_upcoming_for_tenant(ctx[:tenant_id])
      end

    {:ok, Enum.map(events, &summarize/1)}
  rescue
    Ecto.NoResultsError -> {:error, "application not found"}
  end

  defp summarize(e) do
    %{
      "id" => e.id,
      "application_id" => e.application_id,
      "start_at_utc" => e.start_at_utc,
      "end_at_utc" => e.end_at_utc,
      "status" => e.status
    }
  end
end
