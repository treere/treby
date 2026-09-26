defmodule Treby.AI.Tools.ListMembers do
  @moduledoc "Read-only tool: list workspace members."

  def name, do: "list_members"

  def description, do: "List the team members of the workspace with their roles."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    members =
      ctx[:tenant_id]
      |> Treby.Memberships.list_members_for_tenant()
      |> Enum.map(fn m ->
        %{
          "user_id" => m.user_id,
          "name" => m.user && m.user.name,
          "email" => m.user && m.user.email,
          "role" => m.role
        }
      end)

    {:ok, members}
  end
end
