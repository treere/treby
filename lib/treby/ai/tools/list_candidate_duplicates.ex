defmodule Treby.AI.Tools.ListCandidateDuplicates do
  @moduledoc "Read-only tool: list candidate duplicate groups."

  def name, do: "list_candidate_duplicates"

  def description, do: "List groups of likely duplicate candidates in the workspace."

  def destructive?, do: false

  def required_role, do: :admin

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, Treby.Candidates.Duplicates.list_duplicate_groups(ctx[:tenant_id])}
  end
end
