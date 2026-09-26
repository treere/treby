defmodule Treby.AI.Tools.Analytics do
  @moduledoc "Analytics & reporting tools."

  alias Treby.AI.Tools.{
    CandidateCompare,
    DashboardSummary,
    ExplainPage,
    FunnelReport,
    JobViewsReport,
    PipelineStats
  }

  @tools [
    ExplainPage,
    PipelineStats,
    JobViewsReport,
    CandidateCompare,
    FunnelReport,
    DashboardSummary
  ]

  def all, do: @tools
end
