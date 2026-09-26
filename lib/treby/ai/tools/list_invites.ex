defmodule Treby.AI.Tools.ListInvites do
  @moduledoc "Read-only tool: list pending invites (admin)."

  def name, do: "list_invites"

  def description, do: "List the pending team invites of the workspace."

  def destructive?, do: false

  def required_role, do: :admin

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, Treby.Invites.list_invites(ctx[:tenant_id])}
  end
end
