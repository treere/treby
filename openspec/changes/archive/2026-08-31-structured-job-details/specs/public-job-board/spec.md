## MODIFIED Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions across all tenants with structured metadata.

#### Scenario: Each job shows company info and structured meta
- **WHEN** the global board loads
- **THEN** each job listing shows the company logo, company name, job title, salary range, and, when present, location and badge pills for employment/workplace type

#### Scenario: Tenant career page lists show structured meta
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** each job listing shows title, salary, and, when present, location and type badges

#### Scenario: No visible jobs
- **WHEN** there are no visible open positions across any tenant
- **THEN** the page displays "No open positions available"
