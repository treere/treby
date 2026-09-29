defmodule Treby.AI.Tools.DeleteInvite do
  @moduledoc "Destructive tool: delete a pending invite (admin)."

  alias Treby.AI.Tools

  def name, do: "delete_invite"

  def description, do: "Delete a pending team invite."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"invite_id" => %{"type" => "string"}},
      "required" => ["invite_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete invite",
      fields: [
        {"Invite", args["invite_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Enum.find(Treby.Invites.list_invites(ctx[:tenant_id]), &(&1.id == args["invite_id"])) do
        nil ->
          {:error, "invite not found"}

        invite ->
          case Treby.Invites.delete_invite(invite, Tools.actor(ctx)) do
            {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
