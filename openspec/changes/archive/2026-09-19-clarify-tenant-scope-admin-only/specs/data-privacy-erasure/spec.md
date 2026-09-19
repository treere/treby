## MODIFIED Requirements

### Requirement: Tenant erasure is admin-only
The system SHALL allow tenant-scope erasure (Delete company) only to admin members because it anonymizes/deletes company-wide data and requires 7-day grace and slug confirmation, while user-scope erasure (Delete my account) SHALL be available to any authenticated member for their own data.

#### Scenario: Member erases own account
- **WHEN** a member requests erasure with `scope=user`
- **THEN** the erasure is created for that user's own data

#### Scenario: Member cannot erase company data
- **WHEN** a member requests erasure with `scope=tenant`
- **THEN** the system returns an error flash "Only admins can erase company data" and no tenant erasure is created

#### Scenario: Admin erases company data with correct slug
- **WHEN** an admin requests erasure with `scope=tenant` and `confirm` equals the tenant slug
- **THEN** the tenant erasure is created with 7-day grace

#### Scenario: Admin erasure with wrong slug is rejected
- **WHEN** an admin requests erasure with `scope=tenant` and `confirm` does not match the tenant slug
- **THEN** the system returns an error flash "Confirmation does not match company slug"
