# Authentication

## Purpose

Handle user registration, login, session management, and tenant-scoped access control.

## MODIFIED Requirements

### Requirement: User registration
The system SHALL allow users to register with email, password, password confirmation, and Terms of Service acceptance. The email SHALL be verified via a one-time code before the user (and tenant) is created. The system SHALL use the verified email from the session, never client-supplied input.

#### Scenario: Successful registration
- **WHEN** a user has verified their email via a one-time code and submits the full registration form (name, password, password confirmation matching, and accepts Terms of Service)
- **THEN** a new tenant and user are created with the verified email and a bcrypt-hashed password
- **AND** the user is logged in automatically
- **AND** the verified email is cleared from the session

#### Scenario: Duplicate email
- **WHEN** a user tries to verify an email that already belongs to an existing user
- **THEN** no code is sent
- **AND** an inline error is shown on the email field: "has already been taken"

#### Scenario: Password mismatch
- **WHEN** a user submits registration with password and password_confirmation that do not match
- **THEN** the system returns an error: "Passwords do not match"

#### Scenario: Terms of Service not accepted
- **WHEN** a user submits registration without checking the Terms of Service checkbox
- **THEN** the system returns an error: "You must accept the Terms of Service"

#### Scenario: Registration without verified email
- **WHEN** a user attempts the full registration form without having verified their email in the session
- **THEN** the user is redirected to the email verification step