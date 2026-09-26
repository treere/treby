defmodule Treby.AI.Tools.ListActivities do
  @moduledoc "Read-only tool: list activity events."

  def name, do: "list_activities"

  def description, do: "List recent activity events of the workspace, or of one entity."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "entity_type" => %{"type" => "string"},
        "entity_id" => %{"type" => "string"},
        "limit" => %{"type" => "integer"}
      }
    }
  end

  def run(args, ctx) do
    limit = args["limit"] || 20

    events =
      if args["entity_type"] && args["entity_id"] do
        Treby.Activities.list_events_for_entity(args["entity_type"], args["entity_id"], limit)
      else
        Treby.Activities.list_events_for_tenant(ctx[:tenant_id], limit)
      end

    {:ok, events}
  end
end
