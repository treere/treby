defmodule Treby.AI.Tools.InviteMember do
  @moduledoc "Destructive tool: invite a user to the workspace."

  alias Treby.AI.Tools

  def name, do: "invite_member"

  def description, do: "Invite a new team member (admin or member) to the workspace by email."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "email" => %{"type" => "string"},
        "role" => %{"type" => "string", "enum" => ["admin", "member"]}
      },
      "required" => ["email"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "email" => args["email"],
      "role" => args["role"] || "member",
      "tenant_id" => ctx[:tenant_id]
    }

    case Treby.Invites.create_invite(attrs, ctx[:user]) do
      {:ok, invite} -> {:ok, %{"id" => invite.id, "email" => invite.email}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
