## MODIFIED Requirements

### Requirement: User registration
The system SHALL allow users to register with email, password, password confirmation, and Terms of Service acceptance.

#### Scenario: Successful registration
- **WHEN** a user submits email, name, password, password confirmation (matching), and accepts Terms of Service
- **THEN** a new user is created with a bcrypt-hashed password
- **AND** the user is logged in automatically

#### Scenario: Duplicate email
- **WHEN** a user tries to register with an existing email
- **THEN** the system returns an error: "Email already registered"

#### Scenario: Password mismatch
- **WHEN** a user submits registration with password and password_confirmation that do not match
- **THEN** the system returns an error: "Passwords do not match"

#### Scenario: Terms of Service not accepted
- **WHEN** a user submits registration without checking the Terms of Service checkbox
- **THEN** the system returns an error: "You must accept the Terms of Service"
