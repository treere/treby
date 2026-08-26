defmodule Treby.Notifications.Email do
  @moduledoc """
  Email builder functions for notification emails.
  """

  def new_application_confirmation(candidate, job, assigns \\ %{}) do
    Swoosh.Email.new()
    |> Swoosh.Email.to(candidate.email)
    |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
    |> Swoosh.Email.subject("Application Received - #{job.title}")
    |> Swoosh.Email.html_body("""
    <h2>Thank you for applying!</h2>
    <p>Hi #{assigns[:candidate_name] || candidate.name},</p>
    <p>We've received your application for <strong>#{job.title}</strong> at #{assigns[:company_name] || "our company"}.</p>
    <p>Our team will review your application and get back to you soon.</p>
    <p>You can view the job posting <a href="/careers/#{job.id}">here</a>.</p>
    <p>Best regards,<br/>The #{assigns[:company_name] || "Treby"} Team</p>
    """)
    |> Swoosh.Email.text_body("""
    Thank you for applying!

    Hi #{assigns[:candidate_name] || candidate.name},

    We've received your application for #{job.title} at #{assigns[:company_name] || "our company"}.

    Our team will review your application and get back to you soon.

    Best regards,
    The #{assigns[:company_name] || "Treby"} Team
    """)
  end

  def new_application_team_alert(admin, candidate, job, assigns \\ %{}) do
    Swoosh.Email.new()
    |> Swoosh.Email.to(admin.email)
    |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
    |> Swoosh.Email.subject("New Application: #{candidate.name} for #{job.title}")
    |> Swoosh.Email.html_body("""
    <h2>New Application Received</h2>
    <p>Hi #{assigns[:admin_name] || admin.name},</p>
    <p>A new application has been submitted for <strong>#{job.title}</strong>.</p>
    <table style="margin: 20px 0; padding: 15px; background-color: #f9fafb; border-radius: 8px;">
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Candidate</td>
        <td style="padding: 5px 0;"><strong>#{candidate.name}</strong></td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Email</td>
        <td style="padding: 5px 0;">#{candidate.email}</td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Job</td>
        <td style="padding: 5px 0;"><strong>#{job.title}</strong></td>
      </tr>
    </table>
    <p><a href="/app/pipeline/#{job.id}" style="display: inline-block; padding: 10px 20px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">View in Pipeline</a></p>
    """)
    |> Swoosh.Email.text_body("""
    New Application Received

    Hi #{assigns[:admin_name] || admin.name},

    A new application has been submitted for #{job.title}.

    Candidate: #{candidate.name}
    Email: #{candidate.email}
    Job: #{job.title}

    View in Pipeline: /app/pipeline/#{job.id}
    """)
  end

  @doc """
  Sends a magic link email to a candidate for portal access.
  """
  def magic_link_email(candidate, tenant, url) do
    Swoosh.Email.new()
    |> Swoosh.Email.to(candidate.email)
    |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
    |> Swoosh.Email.subject("Access your application portal")
    |> Swoosh.Email.html_body("""
    <h2>Access your portal</h2>
    <p>Hi #{candidate.name},</p>
    <p>Click the button below to access your application portal at #{tenant.name}.</p>
    <p><a href="#{url}" style="display: inline-block; padding: 12px 24px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">Access Portal</a></p>
    <p style="color: #6b7280; font-size: 14px;">This link expires in 15 minutes and can only be used once.</p>
    """)
    |> Swoosh.Email.text_body("""
    Access your portal

    Hi #{candidate.name},

    Click the link below to access your application portal at #{tenant.name}:

    #{url}

    This link expires in 15 minutes and can only be used once.
    """)
  end

  @doc """
  Sends a notification ping email for a new message in the portal.
  """
  def notification_ping(candidate, tenant, conversation_id, notification_type, assigns \\ %{}) do
    {subject, body} = ping_content(notification_type, candidate, tenant, assigns)

    url = "/#{tenant.slug}/portal/messages/#{conversation_id}"

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

  defp ping_content("new_message", _candidate, tenant, assigns) do
    job_title = assigns[:job_title] || "your application"
    {"New message from #{tenant.name}", "You have a new message regarding #{job_title}."}
  end

  defp ping_content("status_change", _candidate, _tenant, assigns) do
    stage = assigns[:stage_name] || "a new stage"
    job_title = assigns[:job_title] || "your application"
    {"Application update: #{stage}", "Your application for #{job_title} has moved to #{stage}."}
  end

  defp ping_content("info_request", _candidate, _tenant, assigns) do
    job_title = assigns[:job_title] || "your application"

    {"Information needed: #{job_title}",
     "We need some additional information to proceed with #{job_title}."}
  end

  defp ping_content("interview_update", _candidate, _tenant, assigns) do
    job_title = assigns[:job_title] || "your application"

    {"Interview update: #{job_title}",
     "There's an update regarding your interview for #{job_title}."}
  end

  defp ping_content("offer", _candidate, _tenant, assigns) do
    job_title = assigns[:job_title] || "your application"
    {"Offer: #{job_title}", "You have received an offer for #{job_title}!"}
  end

  defp ping_content("rejection", _candidate, _tenant, assigns) do
    job_title = assigns[:job_title] || "your application"

    {"Application update: #{job_title}",
     "There's an update regarding your application for #{job_title}."}
  end
end
