defmodule Treby.AI.Tools.Analytics do
  @moduledoc "Analytics & reporting tools."

  alias Treby.AI.Tools.{
    ExplainPage,
    PipelineStats,
    JobViewsReport,
    CandidateCompare,
    FunnelReport
  }

  @tools [
    ExplainPage,
    PipelineStats,
    JobViewsReport,
    CandidateCompare,
    FunnelReport
  ]

  def all, do: @tools
end
