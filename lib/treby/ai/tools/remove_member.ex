defmodule Treby.AI.Tools.RemoveMember do
  @moduledoc "Destructive tool: remove a user from the workspace."

  alias Treby.AI.Tools

  def name, do: "remove_member"

  def description, do: "Remove a user from the workspace."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "user_id" => %{"type" => "string", "description" => "User id to remove"}
      },
      "required" => ["user_id"]
    }
  end

  def run(args, ctx) do
    case Treby.Memberships.remove_membership_by_ids(args["user_id"], ctx[:tenant_id], ctx[:user]) do
      {:ok, _} -> {:ok, %{"removed" => args["user_id"]}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
