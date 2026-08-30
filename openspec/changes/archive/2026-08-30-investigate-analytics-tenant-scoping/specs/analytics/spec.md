## ADDED Requirements

### Requirement: Tenant-isolated analytics

The system SHALL scope all analytics queries by tenant_id so one tenant cannot see another tenant's candidates.

#### Scenario: All pipelines view is tenant-scoped

- **WHEN** a user views Analytics with "All pipelines" selected
- **THEN** Total Candidates, pipeline counts, source breakdown, avg time to hire, conversion rates reflect only that tenant's data

#### Scenario: Two tenants isolated

- **WHEN** tenant A has 2 candidates and tenant B has 3 candidates
- **THEN** tenant A's analytics shows 2 total candidates and tenant B shows 3, not 5
