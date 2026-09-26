defmodule Treby.AI.Tools.UpdateMemberRole do
  @moduledoc "Destructive tool: change a member's role (admin)."

  alias Treby.AI.Tools

  def name, do: "update_member_role"

  def description, do: "Change a team member's role in the workspace to admin or member."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "user_id" => %{"type" => "string"},
        "role" => %{"type" => "string", "enum" => ["admin", "member"]}
      },
      "required" => ["user_id", "role"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Memberships.get_membership(args["user_id"], ctx[:tenant_id]) do
        nil ->
          {:error, "member not found"}

        membership ->
          case Treby.Memberships.update_membership(
                 membership,
                 %{"role" => args["role"]},
                 Tools.actor(ctx)
               ) do
            {:ok, updated} -> {:ok, %{"user_id" => updated.user_id, "role" => updated.role}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
