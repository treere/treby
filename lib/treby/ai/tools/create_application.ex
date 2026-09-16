defmodule Treby.AI.Tools.CreateApplication do
  @moduledoc "Destructive tool: apply a candidate to a job."

  alias Treby.AI.Tools

  def name, do: "create_application"

  def description,
    do: "Create a job application linking a candidate to a job at a given pipeline stage."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "job_id" => %{"type" => "string"},
        "candidate_id" => %{"type" => "string"},
        "pipeline_stage_id" => %{"type" => "string", "description" => "Starting stage id"},
        "applied_at" => %{"type" => "string", "description" => "ISO8601 datetime (optional)"}
      },
      "required" => ["job_id", "candidate_id", "pipeline_stage_id"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "tenant_id" => ctx[:tenant_id],
      "job_id" => args["job_id"],
      "candidate_id" => args["candidate_id"],
      "pipeline_stage_id" => args["pipeline_stage_id"],
      "applied_at" => args["applied_at"] || DateTime.utc_now() |> DateTime.to_iso8601()
    }

    case Treby.Pipeline.create_application(attrs, []) do
      {:ok, application} -> {:ok, %{"id" => application.id}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
