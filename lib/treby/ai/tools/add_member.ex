defmodule Treby.AI.Tools.AddMember do
  @moduledoc "Destructive tool: add a user to the workspace."

  alias Treby.AI.Tools

  def name, do: "add_member"

  def description, do: "Add an existing user to the workspace as admin or member."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "user_id" => %{"type" => "string", "description" => "Existing user id"},
        "role" => %{"type" => "string", "enum" => ["admin", "member"]}
      },
      "required" => ["user_id"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "user_id" => args["user_id"],
      "tenant_id" => ctx[:tenant_id],
      "role" => args["role"] || "member"
    }

    case Treby.Memberships.create_membership(attrs) do
      {:ok, membership} -> {:ok, %{"id" => membership.id}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
