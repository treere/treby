defmodule Treby.AI.Tools.CreateCandidate do
  @moduledoc "Destructive tool: create or find a candidate in the current tenant."

  alias Treby.AI.Tools

  @fields ~w(name email phone linkedin_url custom_fields)

  def name, do: "create_candidate"

  def description,
    do: "Create a new candidate, or return the existing one when the email already matches."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string", "description" => "Full name"},
        "email" => %{"type" => "string", "description" => "Email address"},
        "phone" => %{"type" => "string"},
        "linkedin_url" => %{"type" => "string"},
        "custom_fields" => %{"type" => "object"}
      },
      "required" => ["name", "email"]
    }
  end

  def run(args, ctx) do
    attrs =
      args
      |> Map.take(@fields)
      |> Map.put("tenant_id", ctx[:tenant_id])

    case Treby.Candidates.create_or_find(ctx[:tenant_id], attrs) do
      {:ok, candidate} ->
        {:ok, %{"id" => candidate.id, "name" => candidate.name, "email" => candidate.email}}

      {:error, reason} ->
        {:error, Tools.format_errors(reason)}
    end
  end
end
