## MODIFIED Requirements

### Requirement: Company default availability is configurable
The system SHALL allow admins to configure company-wide default availability hours that apply to newly created team members, and the setting SHALL be discoverable under Organization (primary) with a cross-link under Scheduling.

#### Scenario: Admin finds Company Availability under Organization
- **WHEN** an admin views the Settings sidebar
- **THEN** "Company Availability" appears under the Organization group with an `Admin` badge

#### Scenario: Admin finds cross-link under Scheduling
- **WHEN** an admin views the Scheduling group in the sidebar
- **THEN** a muted row "Manage company defaults →" links to the same Company Availability route

#### Scenario: Non-admin cannot access Company Availability
- **WHEN** a non-admin member attempts to open `/app/settings/company-availability`
- **THEN** access is denied or redirected according to the existing role guard
