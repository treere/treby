defmodule Treby.AI.Tools.FunnelReport do
  @moduledoc "Read-only tool: hiring funnel conversion."

  def name, do: "funnel_report"

  def description, do: "Report the hiring funnel: conversion rates between pipeline stages."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, %{"funnel" => Treby.Pipeline.stage_conversion_rates(ctx[:tenant_id], nil)}}
  end
end
