defmodule Treby.AI.Tools.MergeCandidates do
  @moduledoc "Destructive tool: merge duplicate candidates into a primary one."

  alias Treby.AI.Tools

  def name, do: "merge_candidates"

  def description,
    do:
      "Merge one or more duplicate candidates into a primary candidate, tombstoning the absorbed ones."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "primary_id" => %{"type" => "string", "description" => "Candidate to keep"},
        "candidate_ids" => %{
          "type" => "array",
          "items" => %{"type" => "string"},
          "description" => "Candidates to absorb into the primary"
        }
      },
      "required" => ["primary_id", "candidate_ids"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      tenant_id = ctx[:tenant_id]

      primary = Treby.Candidates.get_candidate(tenant_id, args["primary_id"])

      absorbed =
        args["candidate_ids"]
        |> List.wrap()
        |> Enum.map(&Treby.Candidates.get_candidate(tenant_id, &1))
        |> Enum.reject(&is_nil/1)

      cond do
        is_nil(primary) ->
          {:error, "primary candidate not found"}

        absorbed == [] ->
          {:error, "no candidates to merge"}

        true ->
          case Treby.Candidates.Merge.merge_candidates(primary, absorbed, Tools.actor(ctx)) do
            {:ok, merged} -> {:ok, %{"id" => merged.id, "name" => merged.name}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
