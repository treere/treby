defmodule Treby.AI.Tools.CreateJob do
  @moduledoc "Destructive tool: create a job in the current tenant."

  alias Treby.AI.Tools

  @fields ~w(title description status visible location employment_type workplace_type salary_range)

  def name, do: "create_job"

  def description, do: "Create a new job posting in the current workspace."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "title" => %{"type" => "string", "description" => "Job title"},
        "description" => %{"type" => "string", "description" => "Job description"},
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
      "required" => ["title", "description"]
    }
  end

  def run(args, ctx) do
    attrs =
      args
      |> Map.take(@fields)
      |> Map.put("tenant_id", ctx[:tenant_id])
      |> Map.put("actor_id", ctx[:user] && ctx[:user].id)

    case Treby.Jobs.create_job(attrs) do
      {:ok, job} -> {:ok, %{"id" => job.id, "title" => job.title}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
