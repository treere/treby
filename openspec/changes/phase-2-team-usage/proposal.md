## Why

Phase 1 made Treby usable for a single hiring manager. But hiring is a team sport. Right now any member can invite/remove people, manage pipelines, and do everything an admin can — roles are stored but not enforced. Teams also need structured ways to evaluate candidates (not just free-text notes), automated communication when stages change, and better analytics to understand where their pipeline is stuck. Without these, a 3-person hiring team will still coordinate outside Treby (Slack, spreadsheets, memory).

## What Changes

- **Role-based access control**: Enforce admin vs member permissions. Admins manage settings, team, and destructive actions. Members view everything, add notes, move candidates, schedule interviews.
- **Interview scorecards**: Structurable evaluation criteria (e.g., "Technical Skills 1-5", "Culture Fit YES/NO/MAYBE") per interview. Admins define templates, interviewers fill them out.
- **Stage-based email templates**: When moving a candidate to a stage (Rejected, Offer, etc.), optionally send a templated email. Admins configure templates per stage with variable support.
- **Pipeline selector on analytics**: Analytics currently only shows the default pipeline. Add a dropdown to select any pipeline or view all.
- **Time-in-stage metrics**: Track how long candidates sit in each stage. Show average time per stage on analytics as a bottleneck indicator.

## Capabilities

### New Capabilities

- `role-based-access`: Enforce admin vs member permissions across all LiveViews and context functions.
- `interview-scorecards`: Structured evaluation forms for interviews with configurable criteria and scoring.
- `stage-email-templates`: Configurable email templates triggered when candidates move to specific pipeline stages.

### Modified Capabilities

- `pipeline`: Add pipeline selector to analytics page. Add time-in-stage computation and display.
- `analytics`: Add pipeline dropdown, time-in-stage chart, per-pipeline conversion rates.

## Impact

- **Schema**: New `scorecard_templates` table, `scorecards` table, `email_templates` table. Possibly `application_stage_history` for time tracking (or compute from activity_log).
- **Context modules**: New `Treby.Scorecards`, `Treby.EmailTemplates`. Extensions to `Treby.Pipeline` (stage history), `Treby.Analytics` (pipeline selector, time metrics). RBAC checks added to `Treby.Accounts` and relevant LiveViews.
- **LiveViews**: Modified `AnalyticsLive.Index` (pipeline selector, time-in-stage), modified `SettingsLive.*` (new settings pages for scorecard templates and email templates), RBAC hooks on all authenticated LiveViews.
- **Router**: New routes under `/app/settings` for scorecard and email template configuration.
- **Email**: Extended Swoosh integration for stage-based templated emails.
