# Dashboard

## Delta

## MODIFIED Requirements

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