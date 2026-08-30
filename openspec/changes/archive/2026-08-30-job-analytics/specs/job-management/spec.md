## ADDED Requirements

### Requirement: Analytics navigation from job detail
The system SHALL expose navigation from a job's internal detail page to its per-job analytics page.

#### Scenario: Analytics link visible on job detail
- **WHEN** an authenticated team member views the job detail page at `/app/jobs/:id`
- **THEN** an "Analytics" link/button (with chart/bar icon) is visible in the header actions area alongside "Copy Public Link", "Edit", and "View Pipeline"
- **AND** clicking it navigates to `/app/jobs/:id/analytics`

#### Scenario: Job list shows view indicators
- **WHEN** a team member views the job listing page at `/app/jobs`
- **THEN** each job row displays synthetic view metrics: total views and views in last 7 days (e.g., "123 views · 12 in last 7 days"), or a muted "No views yet" if the job has zero views
- **AND** the indicators are scoped to the current tenant (no cross-tenant leakage)

#### Scenario: Job detail header shows view summary
- **WHEN** a team member views the job detail page at `/app/jobs/:id`
- **THEN** a summary badge near the title shows total views and last-7-days views for that job (or "No views yet"), consistent with the analytics page KPIs
