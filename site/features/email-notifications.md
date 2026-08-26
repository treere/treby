# Email Notifications

Automated email notifications keep candidates and team members informed at every pipeline stage.

## Stage-Based Templates

Configure email templates for each pipeline stage in **Settings**. When a candidate moves to a stage, an email is sent automatically.

Templates support variables:
- `{candidate_name}` — the candidate's name
- `{job_title}` — the position they applied for
- `{company_name}` — your company's name

## Email Types

| Type | Trigger | Recipient |
|---|---|---|
| Application Received | Candidate applies via career page | Candidate |
| Moving Forward | Moved to Screen or Interview stages | Candidate |
| Interview Confirmation | Interview is scheduled | Candidate |
| Offer Letter | Moved to Offer stage | Candidate |
| Not Moving Forward | Moved to Rejected stage | Candidate |
| Team Invitation | Admin invites a new team member | New member |

## Technical Details

Emails are sent via [Swoosh](https://hexdocs.pm/swoosh), the Elixir email library. In development, use the Swoosh mailbox at `/dev/mailbox` to preview emails. Configure your SMTP provider in production.

## Notification Pings (Portal Mode)

When the candidate portal is enabled, candidate-facing emails become short **pings** instead of full message bodies. A ping links directly to the portal where the candidate can see the full message in context.

- **Stage change pings**: Short notification with stage name, linking to the portal dashboard
- **Rejection pings**: Include structured rejection reason; full feedback visible in the portal conversation
- **Interview invite pings**: Link to the portal conversation where details are posted

Candidates can configure which events generate pings in their portal settings. A "important only" filter suppresses non-critical notifications.
