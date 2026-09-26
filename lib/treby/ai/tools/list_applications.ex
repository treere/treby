defmodule Treby.AI.Tools.ListApplications do
  @moduledoc "Read-only tool: list applications for a job or a candidate."

  def name, do: "list_applications"

  def description, do: "List job applications for a job or a candidate."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "job_id" => %{"type" => "string"},
        "candidate_id" => %{"type" => "string"}
      }
    }
  end

  def run(args, ctx) do
    cond do
      args["job_id"] ->
        if Treby.Jobs.get_job(ctx[:tenant_id], args["job_id"]) do
          {:ok, Treby.Pipeline.list_applications_for_job(args["job_id"])}
        else
          {:error, "job not found"}
        end

      args["candidate_id"] ->
        {:ok,
         Treby.Pipeline.list_applications_for_candidate(ctx[:tenant_id], args["candidate_id"])}

      true ->
        {:error, "provide job_id or candidate_id"}
    end
  end
end
