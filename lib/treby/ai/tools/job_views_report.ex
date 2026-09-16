defmodule Treby.AI.Tools.JobViewsReport do
  @moduledoc "Read-only tool: job posting view statistics."

  def name, do: "job_views_report"

  def description, do: "Report views and apply conversions for a single job posting."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "job_id" => %{"type" => "string", "description" => "Job posting id"}
      },
      "required" => ["job_id"]
    }
  end

  def run(args, ctx) do
    case Treby.JobViews.get_summary(ctx[:tenant_id], args["job_id"]) do
      {:ok, summary} -> {:ok, summary}
      _ -> {:error, "job not found"}
    end
  end
end
