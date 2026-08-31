# Dashboard

## Purpose

Provide an actionable hiring dashboard that shows hiring managers what needs their attention, what's coming up, and how hiring is progressing.

## Requirements

### Requirement: Upcoming interviews
The system SHALL display upcoming interviews for the current user.

#### Scenario: Dashboard shows upcoming interviews
- **WHEN** a user visits the dashboard
- **THEN** interviews scheduled for the current user within the next 7 days are displayed
- **AND** each interview shows candidate name, job title, date/time, and link

### Requirement: Stale candidate alerts
The system SHALL identify candidates that need follow-up.

#### Scenario: Stale candidates shown
- **WHEN** a user visits the dashboard
- **THEN** candidates with no activity (stage change, note, interview) for more than 5 days are listed
- **AND** each stale candidate shows name, job title, current stage, and days since last activity

#### Scenario: No stale candidates
- **WHEN** there are no stale candidates
- **THEN** the stale candidates section shows "All caught up!" or is hidden

### Requirement: Pipeline snapshot
The system SHALL show a summary of candidate counts per stage for each open job, resolving each job's effective pipeline (explicit pipeline if assigned, otherwise the tenant's default pipeline).

#### Scenario: Pipeline overview on dashboard
- **WHEN** a user visits the dashboard
- **THEN** each open job shows a horizontal bar with candidate counts per stage
- **AND** the total candidate count per job is displayed

#### Scenario: Open job with no explicit pipeline
- **WHEN** a user visits the dashboard and an open job has no explicit pipeline assigned
- **THEN** the job appears in the pipeline overview
- **AND** its candidate counts are computed against the tenant's default pipeline stages

#### Scenario: No open jobs
- **WHEN** there are no open jobs in the pipeline
- **THEN** the pipeline overview section displays a guided empty state with an icon, title ("No open jobs yet"), description, and a "Create a job" button linking to the jobs page

### Requirement: Weekly stats
The system SHALL show summary statistics for the current week.

#### Scenario: This week's activity
- **WHEN** a user visits the dashboard
- **THEN** the following stats are shown for the current calendar week: applications received, interviews completed, offers sent, hires made

#### Scenario: New user with no activity
- **WHEN** a user with no activity this week visits the dashboard
- **THEN** stat cards display `0` values with clear labels indicating the time period ("This Week")
- **AND** the stat cards are visually present but not the focal point (the onboarding checklist and welcome message take priority above them)

### Requirement: My Actions panel
The system SHALL display a "My Actions" panel on the dashboard showing the current user's outstanding hiring work, alongside the existing upcoming-interviews, stale-candidates, pipeline-snapshot, and weekly-stats panels.

#### Scenario: My Actions panel shown on dashboard
- **WHEN** a user visits the dashboard
- **THEN** a "My Actions" panel is displayed
- **AND** the panel shows pending scorecards for the current user with a direct "Fill scorecard" action
- **AND** the panel shows a read-only "waiting on others" list of applications blocked by other people's outstanding work

#### Scenario: My Actions panel with no pending work
- **WHEN** a user visits the dashboard and has no pending scorecards
- **THEN** the "My Actions" panel shows an empty state instead of an empty list

### Requirement: Dashboard localization (IT/EN)
The system SHALL render all dashboard user-facing text via Gettext so that the dashboard is fully bilingual in Italian and English and respects the user's selected locale. This is the reference implementation for the app-wide bilingual rule.

#### Scenario: Dashboard headings and welcome message in Italian
- **WHEN** a user with the Italian locale visits the dashboard
- **THEN** the page title, welcome message (with interpolated user name), and section headings (Weekly Stats, My Actions, Upcoming Interviews, Stale Candidates, Pipeline Snapshot) are shown in Italian

#### Scenario: My Actions and weekly-stats labels in Italian
- **WHEN** a user with the Italian locale views the dashboard My Actions panel and weekly-stats cards
- **THEN** labels such as "Scorecards to fill", "Waiting on others", "Fill scorecard", "Applications This Week", "Interviews This Week", "Offers This Week", "Hires This Week" are shown in Italian

#### Scenario: Dashboard empty states in Italian
- **WHEN** a user with the Italian locale views an empty dashboard section (no pending scorecards, no upcoming interviews, no stale candidates, no open jobs)
- **THEN** each empty-state title, description, and action label (e.g., "All caught up", "No upcoming interviews", "No open jobs yet", "Create your first job") is shown in Italian

#### Scenario: Dashboard flash messages in Italian
- **WHEN** a user with the Italian locale submits a scorecard from the dashboard
- **THEN** success and error flash messages (e.g., "Scorecard submitted", "Failed to submit scorecard") are shown in Italian

#### Scenario: Activity and interview labels in Italian
- **WHEN** a user with the Italian locale views activity feed entries and upcoming interview rows
- **THEN** activity labels ("New application", "Interview scheduled", "Stage change", etc.) and interviewer placeholders ("To be determined") are shown in Italian

#### Scenario: Dashboard still renders in English for English locale
- **WHEN** a user with the English locale visits the dashboard
- **THEN** all dashboard text is shown in English (no regression)

#### Scenario: Dashboard has no missing Italian translations
- **WHEN** the dashboard localization is complete
- **THEN** every `msgid` introduced for dashboard strings has a non-empty `msgstr` in `priv/gettext/it/LC_MESSAGES/default.po`
- **AND** `mix treby.check_translations` passes for those keys
