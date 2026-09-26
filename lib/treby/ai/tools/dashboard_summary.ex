defmodule Treby.AI.Tools.DashboardSummary do
  @moduledoc "Read-only tool: workspace dashboard summary."

  def name, do: "dashboard_summary"

  def description,
    do:
      "Summarize the workspace dashboard: counts, actions, upcoming interviews and stale candidates."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, Treby.Dashboard.get_dashboard_data(ctx[:tenant_id], Treby.AI.Tools.actor_id(ctx))}
  end
end
