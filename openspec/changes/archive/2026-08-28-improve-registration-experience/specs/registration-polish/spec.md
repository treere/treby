# Registration Polish

## Delta

## ADDED Requirements

### Requirement: Company page slug auto-derivation
The system SHALL derive the company page slug automatically from the company name during registration, without requiring the user to enter a slug. The slug SHALL be unique among tenants.

#### Scenario: Registration without slug input
- **WHEN** a user fills the registration form (company name, user details, password, ToS) with no slug field
- **THEN** the account is created
- **AND** a slug derived from the company name is assigned to the tenant

#### Scenario: Slug collision
- **WHEN** the derived slug already exists for another tenant
- **THEN** a unique suffix is appended (e.g., `-2`) so the slug remains unique

#### Scenario: Career page available after registration
- **WHEN** a new tenant logs in for the first time after registration
- **THEN** visiting `/:tenant_slug/careers` shows the tenant's career page rather than a "coming soon" fallback

## ADDED Requirements

### Requirement: Field-level registration errors
The system SHALL display specific field-level validation errors on the registration form when registration fails.

#### Scenario: Duplicate email
- **WHEN** a user registers with an email that is already in use
- **THEN** the form re-renders with an inline error on the email field
- **AND** a clear error message is displayed explaining the specific problem

#### Scenario: Invalid registration data
- **WHEN** a user submits registration with invalid data (e.g., short password, missing confirmation, mismatched passwords)
- **THEN** inline errors are shown on each affected field
- **AND** the user stays on the registration form