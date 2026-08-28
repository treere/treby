# Email Notifications

Treby uses email sparingly: **login codes** and **notification pings**. All real communication lives inside the candidate portal.

## What emails remain

| Email | When | Purpose |
|---|---|---|
| Login code (OTP) | Candidate requests portal access | 6-digit one-time code, valid 10 minutes |
| Notification pings | Something happened in the portal | Short "check your portal" notice with a link to the panel |

Email is never used to deliver content (interview details, stage updates, offers, messages). Those live in the portal conversation; the email only tells the candidate to go look.

## Message Templates

Instead of stage-based email templates, Treby provides **message templates** configured in **Settings → Message Templates**. When a candidate moves to a stage, the recruiter can post the rendered template into the candidate's portal conversation — immediately, on a schedule, or skip it.

Templates support variables:
- `{candidate_name}` — the candidate's name
- `{job_title}` — the position they applied for
- `{company_name}` — your company's name
- `{stage_name}` — the stage name
- `{recruiter_name}` — the user who moved the candidate

## Notification Pings

Candidate-facing pings are short and link back to the portal (`/portal`):

- **New application** — "Thank you for applying… track your application in your panel"
- **Stage change** — "Your application for {job_title} has moved to {stage}"
- **New message** — "You have a new message regarding {job_title}"
- **Interview update** — "There's an update regarding your interview"
- **Rejection** — "There's an update regarding your application"

Candidates can configure which events generate pings in their portal settings, including an "important only" filter.

## Team Notifications

Team members (recruiters, admins, examiners) receive **no emails**. New applications, scheduled interviews, and pipeline changes are recorded in the in-app **Recent Activity** feed on the dashboard.

## Technical Details

Emails are sent via [Swoosh](https://hexdocs.pm/swoosh). In development, use the Swoosh mailbox at `/dev/mailbox` to preview emails. Configure your SMTP provider in production.