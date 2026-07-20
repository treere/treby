defmodule Treby.SchedulingEmail do
  @moduledoc """
  Email templates for interview scheduling notifications.
  """

  import Swoosh.Email

  def interview_scheduled_candidate(candidate, interviewer, job, meet_link, start_at) do
    new()
    |> to(candidate.email)
    |> from({"Treby", "noreply@treby.app"})
    |> subject("Interview Scheduled - #{job.title}")
    |> html_body("""
    <h2>Your interview has been scheduled</h2>
    <p>Hi #{candidate.name},</p>
    <p>Your interview for <strong>#{job.title}</strong> has been scheduled.</p>
    <table style="margin: 20px 0; padding: 15px; background-color: #f9fafb; border-radius: 8px;">
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Interviewer</td>
        <td style="padding: 5px 0;"><strong>#{interviewer.name}</strong></td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Date & Time</td>
        <td style="padding: 5px 0;"><strong>#{format_datetime(start_at)}</strong></td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Meeting Link</td>
        <td style="padding: 5px 0;"><a href="#{meet_link}" style="color: #2563eb;">#{meet_link}</a></td>
      </tr>
    </table>
    <p>We look forward to speaking with you!</p>
    """)
    |> text_body("""
    Your interview has been scheduled

    Hi #{candidate.name},

    Your interview for #{job.title} has been scheduled.

    Interviewer: #{interviewer.name}
    Date & Time: #{format_datetime(start_at)}
    Meeting Link: #{meet_link}

    We look forward to speaking with you!
    """)
  end

  def interview_scheduled_interviewer(interviewer, candidate, job, meet_link, start_at) do
    new()
    |> to(interviewer.email)
    |> from({"Treby", "noreply@treby.app"})
    |> subject("Interview Scheduled - #{candidate.name} - #{job.title}")
    |> html_body("""
    <h2>New interview scheduled</h2>
    <p>Hi #{interviewer.name},</p>
    <p>You have an interview scheduled with <strong>#{candidate.name}</strong> for <strong>#{job.title}</strong>.</p>
    <table style="margin: 20px 0; padding: 15px; background-color: #f9fafb; border-radius: 8px;">
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Candidate</td>
        <td style="padding: 5px 0;"><strong>#{candidate.name}</strong></td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Date & Time</td>
        <td style="padding: 5px 0;"><strong>#{format_datetime(start_at)}</strong></td>
      </tr>
      <tr>
        <td style="padding: 5px 15px 5px 0; color: #6b7280;">Meeting Link</td>
        <td style="padding: 5px 0;"><a href="#{meet_link}" style="color: #2563eb;">#{meet_link}</a></td>
      </tr>
    </table>
    """)
    |> text_body("""
    New interview scheduled

    Hi #{interviewer.name},

    You have an interview scheduled with #{candidate.name} for #{job.title}.

    Candidate: #{candidate.name}
    Date & Time: #{format_datetime(start_at)}
    Meeting Link: #{meet_link}
    """)
  end

  defp format_datetime(dt) do
    Elixir.Calendar.strftime(dt, "%B %d, %Y at %H:%M UTC")
  end
end
