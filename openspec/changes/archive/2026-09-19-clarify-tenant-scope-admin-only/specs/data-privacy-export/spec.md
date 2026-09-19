## MODIFIED Requirements

### Requirement: Tenant data export is admin-only
The system SHALL allow tenant-scope export only to admin members because it contains company-wide PII (all candidates, applications, audit, jobs), while user-scope export SHALL be available to any authenticated member for their own data.

#### Scenario: Member exports own data
- **WHEN** a member with role "member" requests export with `scope=user`
- **THEN** the export is created and the member can download their own data

#### Scenario: Member cannot export tenant data
- **WHEN** a member requests export with `scope=tenant`
- **THEN** the system returns an error flash "Only admins can export tenant data" and no tenant export is created

#### Scenario: Admin exports tenant data
- **WHEN** an admin requests export with `scope=tenant`
- **THEN** the tenant export is created
