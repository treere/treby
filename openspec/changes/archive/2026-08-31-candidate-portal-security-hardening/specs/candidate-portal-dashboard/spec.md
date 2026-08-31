## MODIFIED Requirements

### Requirement: Candidate dashboard ownership
The system SHALL enforce that a candidate can only view their own applications and tenant data.

#### Scenario: View own application detail
- **WHEN** a candidate clicks an application they own
- **THEN** the detail pane shows the job title, status badge, timeline, and messages for that application

#### Scenario: Attempt to view another candidate's application
- **WHEN** a candidate tries to open an application id that does not belong to them (within same tenant or cross-tenant)
- **THEN** the system does not reveal the other application
- **AND** it shows an error or redirects without leaking existence beyond a generic not-found

#### Scenario: Tenant slug mismatch
- **WHEN** a candidate with tenant A visits `/:other_slug/portal` while authenticated
- **THEN** the system redirects to the candidate's own tenant portal slug or shows a tenant-mismatch error
- **AND** no data from the other tenant is displayed
