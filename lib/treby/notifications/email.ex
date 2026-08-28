defmodule Treby.Notifications.Email do
  @moduledoc """
  Email builder functions for notification emails.

  Emails are limited to two roles: OTP login codes and short notification
  pings linking back to the candidate portal.
  """

  @doc """
  Sends an OTP login email to a candidate with the one-time code.
  """
  def otp_email(candidate, tenant, code) do
    Swoosh.Email.new()
    |> Swoosh.Email.to(candidate.email)
    |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
    |> Swoosh.Email.subject("Your login code")
    |> Swoosh.Email.html_body("""
    <h2>Your login code</h2>
    <p>Hi #{candidate.name},</p>
    <p>Use the code below to access your application portal at #{tenant.name}:</p>
    <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #2563eb;">#{code}</p>
    <p>This code expires in 10 minutes and can only be used once.</p>
    <p><a href="/#{tenant.slug}/portal/verify" style="display: inline-block; padding: 12px 24px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">Enter your code</a></p>
    """)
    |> Swoosh.Email.text_body("""
    Your login code

    Hi #{candidate.name},

    Use the code below to access your application portal at #{tenant.name}:

    #{code}

    This code expires in 10 minutes and can only be used once.

    Enter it here: /#{tenant.slug}/portal/verify
    """)
  end

  @doc """
  Sends a notification ping email for a new message in the portal.
  The email is a short notification linking back to the panel (never full content).
  """
  def notification_ping(candidate, tenant, _conversation_id, notification_type, assigns \\ %{}) do
    {subject, body} = ping_content(notification_type, candidate, tenant, assigns)
    url = "/#{tenant.slug}/portal"

    Swoosh.Email.new()
    |> Swoosh.Email.to(candidate.email)
    |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
    |> Swoosh.Email.subject(subject)
    |> Swoosh.Email.html_body("""
    <p>#{body}</p>
    <p><a href="#{url}" style="display: inline-block; padding: 10px 20px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">View in Portal</a></p>
    """)
    |> Swoosh.Email.text_body("""
    #{body}

    View in Portal: #{url}
    """)
  end

  defp ping_content("new_application", _candidate, tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"

    {"Application received at #{tenant.name}",
     "Thank you for applying for #{job_title}. You can track your application in your panel."}
  end

  defp ping_content("new_message", _candidate, tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"
    {"New message from #{tenant.name}", "You have a new message regarding #{job_title}."}
  end

  defp ping_content("status_change", _candidate, _tenant, assigns) do
    stage = fetch_assign(assigns, :stage_name) || "a new stage"
    job_title = fetch_assign(assigns, :job_title) || "your application"
    {"Application update: #{stage}", "Your application for #{job_title} has moved to #{stage}."}
  end

  defp ping_content("info_request", _candidate, _tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"

    {"Information needed: #{job_title}",
     "We need some additional information to proceed with #{job_title}."}
  end

  defp ping_content("interview_update", _candidate, _tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"

    {"Interview update: #{job_title}",
     "There's an update regarding your interview for #{job_title}."}
  end

  defp ping_content("offer", _candidate, _tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"
    {"Offer: #{job_title}", "You have received an offer for #{job_title}!"}
  end

  defp ping_content("rejection", _candidate, _tenant, assigns) do
    job_title = fetch_assign(assigns, :job_title) || "your application"

    {"Application update: #{job_title}",
     "There's an update regarding your application for #{job_title}."}
  end

  defp fetch_assign(assigns, key) do
    assigns[key] || assigns[to_string(key)]
  end
end
