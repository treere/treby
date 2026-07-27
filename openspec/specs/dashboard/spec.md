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
The system SHALL show a summary of candidate counts per stage for each open job.

#### Scenario: Pipeline overview on dashboard
- **WHEN** a user visits the dashboard
- **THEN** each open job shows a horizontal bar with candidate counts per stage
- **AND** the total candidate count per job is displayed

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
