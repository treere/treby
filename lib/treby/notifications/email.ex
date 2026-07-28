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
end
