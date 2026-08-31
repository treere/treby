## ADDED Requirements

### Requirement: Admin-only audit log access
The system SHALL restrict the audit log view and audit query API to admin users only, consistent with other settings pages.

#### Scenario: Admin accesses audit log
- **WHEN** an admin navigates to `/:company/app/settings/audit-log` or queries audit events with a valid admin scope
- **THEN** the request succeeds and returns tenant-scoped audit events

#### Scenario: Member denied audit log access
- **WHEN** a member navigates to `/:company/app/settings/audit-log` or attempts to query audit events
- **THEN** the system denies access and redirects to the dashboard with a permission-denied flash or returns a permission error for API/context calls

#### Scenario: Audit log respects workspace role
- **WHEN** a user is admin in tenant A but member in tenant B
- **THEN** the audit log is accessible only when the current workspace is tenant A, and denied when the current workspace is tenant B
