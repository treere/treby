defmodule Treby.AI.Tools.DeleteJob do
  @moduledoc "Destructive tool: delete a job in the current tenant."

  alias Treby.AI.Tools

  def name, do: "delete_job"

  def description, do: "Delete a job from the current workspace. Requires confirmation."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "job_id" => %{"type" => "string", "description" => "Job id to delete"}
      },
      "required" => ["job_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Jobs.get_job(ctx[:tenant_id], args["job_id"]) do
        nil ->
          {:error, "job not found"}

        job ->
          case Treby.Jobs.delete_job(job) do
            {:ok, deleted} -> {:ok, %{"id" => deleted.id, "title" => deleted.title}}
            {:error, reason} -> {:error, inspect(reason)}
          end
      end
    end
  end
end
