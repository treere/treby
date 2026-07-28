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
- **THEN** the system returns a flash error: "Passwords do not match"
- **AND** the user is redirected back to the registration form

### Requirement: Terms of Service acceptance on registration
The system SHALL require users to accept Terms of Service before completing registration.

#### Scenario: Successful registration with ToS accepted
- **WHEN** a user submits registration with the Terms of Service checkbox checked
- **THEN** the account is created successfully

#### Scenario: Registration rejected without ToS acceptance
- **WHEN** a user submits registration without checking the Terms of Service checkbox
- **THEN** the system returns a flash error: "You must accept the Terms of Service"
- **AND** the user is redirected back to the registration form

### Requirement: Terms of Service and Privacy Policy pages
The system SHALL provide accessible Terms of Service and Privacy Policy pages.

#### Scenario: User navigates to Terms of Service
- **WHEN** a user visits `/terms`
- **THEN** the system displays a Terms of Service page with "Coming soon" content

#### Scenario: User navigates to Privacy Policy
- **WHEN** a user visits `/privacy`
- **THEN** the system displays a Privacy Policy page with "Coming soon" content
