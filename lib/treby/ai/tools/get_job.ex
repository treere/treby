defmodule Treby.AI.Tools.GetJob do
  @moduledoc "Read-only tool: fetch one job by id."

  def name, do: "get_job"

  def description, do: "Get the details of a single job posting by id."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{"job_id" => %{"type" => "string", "description" => "Job id"}},
      "required" => ["job_id"]
    }
  end

  def run(args, ctx) do
    case Treby.Jobs.get_job(ctx[:tenant_id], args["job_id"]) do
      nil -> {:error, "job not found"}
      job -> {:ok, job}
    end
  end
end
