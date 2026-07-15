defmodule Treby.InvitesEmail do
  @moduledoc """
  Email templates for team invites.
  """

  import Swoosh.Email

  def invite_email(invite, tenant, invite_url) do
    new()
    |> to(invite.email)
    |> from({"Treby", "noreply@treby.app"})
    |> subject("You've been invited to join #{tenant.name} on Treby")
    |> html_body("""
    <h2>You're invited to join #{tenant.name}</h2>
    <p>You've been invited as a <strong>#{invite.role}</strong>.</p>
    <p>Click the link below to accept the invitation:</p>
    <p><a href="#{invite_url}">Accept Invitation</a></p>
    <p>This invitation expires on #{Calendar.strftime(invite.expires_at, "%B %d, %Y")}.</p>
    """)
    |> text_body("""
    You're invited to join #{tenant.name}

    You've been invited as a #{invite.role}.

    Click the link below to accept the invitation:
    #{invite_url}

    This invitation expires on #{Calendar.strftime(invite.expires_at, "%B %d, %Y")}.
    """)
  end
end
