defmodule Treby.AI.Tools.InviteMember do
  @moduledoc "Destructive tool: invite a user to the workspace."

  alias Treby.AI.Tools

  def name, do: "invite_member"

  def description,
    do: "Invite a new team member (admin, recruiter, or interviewer) to the workspace by email."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "email" => %{"type" => "string"},
        "role" => %{"type" => "string", "enum" => ["admin", "recruiter", "interviewer"]}
      },
      "required" => ["email"]
    }
  end

  def summary(args) do
    %{
      title: "Invite team member",
      fields: [
        {"Email", args["email"]},
        {"Role", args["role"]}
      ]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "email" => args["email"],
      "role" => args["role"] || "recruiter",
      "tenant_id" => ctx[:tenant_id]
    }

    case Treby.Invites.create_invite(attrs, Tools.actor(ctx)) do
      {:ok, invite} -> {:ok, %{"id" => invite.id, "email" => invite.email}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
