defmodule Treby.AI.Tools.UpdateCandidate do
  @moduledoc "Destructive tool: update a candidate's profile fields."

  alias Treby.AI.Tools

  @fields ~w(name email phone linkedin_url custom_fields)

  def name, do: "update_candidate"

  def description, do: "Update a candidate's name, email, phone, LinkedIn URL or custom fields."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "string"},
        "name" => %{"type" => "string"},
        "email" => %{"type" => "string"},
        "phone" => %{"type" => "string"},
        "linkedin_url" => %{"type" => "string"},
        "custom_fields" => %{"type" => "object"}
      },
      "required" => ["id"]
    }
  end

  def run(args, ctx) do
    case Treby.Candidates.get_candidate(ctx[:tenant_id], args["id"]) do
      nil ->
        {:error, "candidate not found"}

      candidate ->
        attrs = args |> Map.take(@fields)

        case Treby.Candidates.update_candidate(candidate, attrs, %{}) do
          {:ok, updated} -> {:ok, %{"id" => updated.id, "name" => updated.name}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
    end
  end
end
