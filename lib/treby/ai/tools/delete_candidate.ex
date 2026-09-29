defmodule Treby.AI.Tools.DeleteCandidate do
  @moduledoc "Destructive tool: delete a candidate."

  alias Treby.AI.Tools

  def name, do: "delete_candidate"

  def description, do: "Delete a candidate from the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"id" => %{"type" => "string", "description" => "Candidate id"}},
      "required" => ["id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete candidate",
      fields: [
        {"Id", args["id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Candidates.get_candidate(ctx[:tenant_id], args["id"]) do
        nil ->
          {:error, "candidate not found"}

        candidate ->
          case Treby.Candidates.delete_candidate(candidate, Tools.actor(ctx)) do
            {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
