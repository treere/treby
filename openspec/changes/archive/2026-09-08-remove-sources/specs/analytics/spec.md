## REMOVED Requirements

### Requirement: Source breakdown
**Reason**: Candidate source tracking removed — the breakdown was dominated by "Unknown" and provided no actionable insight.
**Migration**: The source-breakdown card is removed from the Analytics page and `Pipeline.source_breakdown/1,2` is deleted. Pipeline overview, time-to-hire, conversion rates, and time-in-stage cards are unchanged. Job-view traffic-source analytics (`JobViews`) is unaffected.

#### Scenario: Source chart
- **WHEN** a user views analytics
- **THEN** no per-source chart is shown

#### Scenario: Source chart per pipeline
- **WHEN** a user selects a specific pipeline
- **THEN** no source breakdown is shown for that pipeline either

#### Scenario: Source conversion funnel
- **WHEN** a user views analytics
- **THEN** no per-source interview/hired funnel is shown

## MODIFIED Requirements

### Requirement: Tenant-isolated analytics

The system SHALL scope all analytics queries by tenant_id so one tenant cannot see another tenant's candidates.

#### Scenario: All pipelines view is tenant-scoped

- **WHEN** a user views Analytics with "All pipelines" selected
- **THEN** Total Candidates, pipeline counts, avg time to hire, conversion rates reflect only that tenant's data

#### Scenario: Two tenants isolated

- **WHEN** tenant A has 2 candidates and tenant B has 3 candidates
- **THEN** tenant A's analytics shows 2 total candidates and tenant B shows 3, not 5
