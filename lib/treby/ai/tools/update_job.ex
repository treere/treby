defmodule Treby.AI.Tools.UpdateJob do
  @moduledoc "Destructive tool: update a job in the current tenant."

  alias Treby.AI.Tools

  @fields ~w(title description status visible location employment_type workplace_type salary_range)

  def name, do: "update_job"

  def description, do: "Update an existing job of the current workspace."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "job_id" => %{"type" => "string", "description" => "Job id to update"},
        "title" => %{"type" => "string"},
        "description" => %{"type" => "string"},
        "status" => %{"type" => "string", "enum" => ["open", "closed"]},
        "visible" => %{"type" => "boolean"},
        "location" => %{"type" => "string"},
        "employment_type" => %{
          "type" => "string",
          "enum" => ["full_time", "part_time", "contract", "internship"]
        },
        "workplace_type" => %{"type" => "string", "enum" => ["on_site", "hybrid", "remote"]},
        "salary_range" => %{"type" => "string"}
      },
      "required" => ["job_id"]
    }
  end

  def run(args, ctx) do
    tenant_id = ctx[:tenant_id]

    case Treby.Jobs.get_job(tenant_id, args["job_id"]) do
      nil ->
        {:error, "job not found"}

      job ->
        attrs =
          args
          |> Map.take(@fields)
          |> Map.put("actor_id", ctx[:user] && ctx[:user].id)

        case Treby.Jobs.update_job(job, attrs) do
          {:ok, updated} -> {:ok, %{"id" => updated.id, "title" => updated.title}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
    end
  end
end
