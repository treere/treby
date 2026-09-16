defmodule Treby.AI.Tools.ListCandidates do
  @moduledoc "Read-only tool: list candidates in the workspace."

  def name, do: "list_candidates"

  def description,
    do:
      "List candidates in the workspace, optionally filtered by search text, job or pipeline stage."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "search" => %{"type" => "string", "description" => "Free-text search on name/email"},
        "job_id" => %{"type" => "string"},
        "stage_id" => %{"type" => "string"}
      }
    }
  end

  def run(args, ctx) do
    filters =
      %{}
      |> maybe_put("search", args["search"])
      |> maybe_put("job_id", args["job_id"])
      |> maybe_put("stage_id", args["stage_id"])

    result = Treby.Candidates.list_candidates(ctx[:tenant_id], filters)
    entries = if is_tuple(result), do: elem(result, 0), else: result

    {:ok,
     Enum.map(entries, fn c ->
       %{"id" => c.id, "name" => c.name, "email" => c.email, "phone" => c.phone}
     end)}
  end

  defp maybe_put(filters, _key, nil), do: filters
  defp maybe_put(filters, _key, ""), do: filters
  defp maybe_put(filters, key, value), do: Map.put(filters, key, value)
end
