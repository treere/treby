## MODIFIED Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions across all tenants and SHALL be discoverable from the landing page.

#### Scenario: Global board loads
- **WHEN** a visitor navigates to `/careers`
- **THEN** the page displays all open jobs with `visible=true` from all tenants

#### Scenario: Discovery from landing page
- **WHEN** a visitor navigates to `/`
- **THEN** a link to `/careers` is visible in the header and footer
- **AND** following the link loads the global board

#### Scenario: Each job shows company info
- **WHEN** the global board loads
- **THEN** each job listing shows the company logo, company name, job title, and salary range

#### Scenario: No visible jobs
- **WHEN** there are no visible open positions across any tenant
- **THEN** the page displays "No open positions available"
