defmodule Treby.AI.Tools.ListScorecardTemplates do
  @moduledoc "Read-only tool: list scorecard templates."

  def name, do: "list_scorecard_templates"

  def description, do: "List the scorecard templates configured in the workspace."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, Treby.Scorecards.list_scorecard_templates(ctx[:tenant_id])}
  end
end
