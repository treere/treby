defmodule Treby.AI.Tools.PipelineStats do
  @moduledoc "Read-only tool: pipeline counts and conversion rates."

  def name, do: "pipeline_stats"

  def description,
    do: "Report candidate counts per pipeline stage and stage-to-stage conversion rates."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    counts = Treby.Pipeline.pipeline_counts_per_stage(ctx[:tenant_id], nil)
    conversion = Treby.Pipeline.stage_conversion_rates(ctx[:tenant_id], nil)

    {:ok, %{"counts_per_stage" => counts, "conversion_rates" => conversion}}
  end
end
