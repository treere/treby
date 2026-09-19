# Company Availability

## Purpose

Allow administrators to configure the company's default availability template and timezone that new team members inherit when they join.

## Requirements

### Requirement: Company default availability template
The system SHALL maintain a company-level default availability template used to seed new users' availability.

#### Scenario: Template seeded at tenant creation
- **WHEN** a tenant is created
- **THEN** the system creates company default rules for Monday–Friday, 09:00–13:00 and 14:00–18:00, in the company timezone

#### Scenario: Template scope
- **WHEN** availability rules are stored
- **THEN** company template rules are marked with scope `"company"` and have a null `user_id`

### Requirement: Edit company availability (admin only)
The system SHALL allow admin users to view and edit the company default availability template and the company timezone.

#### Scenario: Admin edits template
- **WHEN** an admin opens company availability settings
- **THEN** they can add, edit, and remove company template rules (multiple windows per day) and change the company timezone

#### Scenario: Non-admin blocked
- **WHEN** a non-admin user attempts to access company availability settings
- **THEN** access is forbidden

### Requirement: Company timezone
The system SHALL store a company timezone, set at registration from the browser and editable by admins.

#### Scenario: Set at registration
- **WHEN** a tenant is registered
- **THEN** the company timezone is set from `Intl.DateTimeFormat().resolvedOptions().timeZone`

#### Scenario: Admin changes timezone
- **WHEN** an admin changes the company timezone
- **THEN** all company template rules are interpreted in the new timezone

### Requirement: Company availability discoverability
The system SHALL expose Company Availability under Organization as primary and with a cross-link under Scheduling, both pointing to the same route.

#### Scenario: Admin finds Company Availability under Organization
- **WHEN** an admin views the Settings sidebar
- **THEN** "Company Availability" appears under the Organization group with an `Admin` badge

#### Scenario: Admin finds cross-link under Scheduling
- **WHEN** an admin views the Scheduling group in the sidebar
- **THEN** a muted row "Manage company defaults →" links to the same Company Availability route

#### Scenario: Non-admin cannot access Company Availability
- **WHEN** a non-admin member attempts to open `/app/settings/company-availability`
- **THEN** access is denied or redirected according to the existing role guard
