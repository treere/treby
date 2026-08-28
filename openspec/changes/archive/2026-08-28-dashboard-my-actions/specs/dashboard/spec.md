# Dashboard

## ADDED Requirements

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
