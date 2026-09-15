defmodule Treby.AI.Tools.ListJobs do
  @moduledoc "Read-only tool: list the tenant's jobs."

  def name, do: "list_jobs"

  def description, do: "List the jobs of the current workspace, optionally filtered by status."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "status" => %{
          "type" => "string",
          "enum" => ["open", "closed"],
          "description" => "Only return jobs with this status"
        }
      }
    }
  end

  def run(args, ctx) do
    tenant_id = ctx[:tenant_id]
    opts = if args["status"], do: [status: args["status"]], else: []

    jobs =
      tenant_id
      |> Treby.Jobs.list_jobs(opts)
      |> Enum.map(&%{"id" => &1.id, "title" => &1.title, "status" => &1.status})

    {:ok, jobs}
  end
end
