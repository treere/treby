defmodule Treby.AI.Tools.ListCalendarConnections do
  @moduledoc "Read-only tool: list the user's calendar connections."

  def name, do: "list_calendar_connections"

  def description, do: "List the calendar providers connected by the current user."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    connections =
      ctx
      |> Treby.AI.Tools.actor_id()
      |> Treby.Calendar.list_connections_for_user()
      |> Enum.map(fn c -> %{"provider" => c.provider, "connected" => true} end)

    {:ok, connections}
  end
end
