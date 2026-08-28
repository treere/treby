# Registration Polish

## Purpose

Enhance the registration flow with password confirmation, Terms of Service consent, and legal page stubs.

## Requirements

### Requirement: Password confirmation on registration
The system SHALL require users to confirm their password by entering it twice during registration.

#### Scenario: Successful registration with matching passwords
- **WHEN** a user submits registration with password and password_confirmation that match
- **THEN** the account is created successfully

#### Scenario: Registration rejected with mismatched passwords
- **WHEN** a user submits registration with password and password_confirmation that do not match
- **THEN** the form re-renders with an inline error on the confirmation field: "does not match password"

### Requirement: Terms of Service acceptance on registration
The system SHALL require users to accept Terms of Service before completing registration.

#### Scenario: Successful registration with ToS accepted
- **WHEN** a user submits registration with the Terms of Service checkbox checked
- **THEN** the account is created successfully

#### Scenario: Registration rejected without ToS acceptance
- **WHEN** a user submits registration without checking the Terms of Service checkbox
- **THEN** the form re-renders with an inline error on the checkbox: "must be accepted"

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

### Requirement: Terms of Service and Privacy Policy pages
The system SHALL provide accessible Terms of Service and Privacy Policy pages.

#### Scenario: User navigates to Terms of Service
- **WHEN** a user visits `/terms`
- **THEN** the system displays a Terms of Service page with "Coming soon" content

#### Scenario: User navigates to Privacy Policy
- **WHEN** a user visits `/privacy`
- **THEN** the system displays a Privacy Policy page with "Coming soon" content
