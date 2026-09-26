# AI Agent

## MODIFIED Requirements

### Requirement: Extended tool coverage

The tool registry SHALL cover every staff-facing context of the system, not only job CRUD,
and SHALL expose each tool subject to the connected user's membership role. Coverage SHALL
include jobs, candidates (including delete/merge/duplicates), applications and review,
pipeline configuration and stage people, notes (list/update/delete), interviews, scorecards
and templates, calendar and availability, scheduled messages and email templates (including
delete), analytics and dashboard, team members and invites, workspace settings, custom
fields, career page, CSV import and bulk operations, notifications, activities and audit log,
data-privacy requests, and webhooks.

#### Scenario: Recruiter tools available
- **WHEN** the active profile is recruiter
- **THEN** tools include job read/write, candidate read/write, application create/list/move/review, notes, and pipeline reads

#### Scenario: Analytics tools available
- **WHEN** the active profile is analytics
- **THEN** tools include pipeline stats, funnel, job views, candidate comparison, dashboard summary, and page explanation

#### Scenario: Comms tools available
- **WHEN** the active profile is comms
- **THEN** tools include send message, scheduled message list/schedule/cancel/reschedule/retry, and email template read/write

#### Scenario: Admin tools available
- **WHEN** the active profile is admin and the user is a workspace admin
- **THEN** tools include member management, invites, pipeline configuration, custom fields, career page, CSV import and bulk deletion, data-privacy and webhooks

#### Scenario: Admin tools hidden from members
- **WHEN** the active profile is admin but the user is not a workspace admin
- **THEN** admin-only tools are removed from the toolset before the model runs

#### Scenario: Interview and scorecard tools available
- **WHEN** the active profile is recruiter or admin
- **THEN** tools include interview scheduling/list/cancel/complete and scorecard submit/list, with scorecard-template writes reserved for admins
