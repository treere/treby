# Authentication

## Purpose

Handle user registration, login, session management, and tenant-scoped access control.

## Requirements

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

### Requirement: User login
The system SHALL allow users to log in with email and password.

#### Scenario: Successful login
- **WHEN** a user submits valid email and password
- **THEN** a session is created with user_id and tenant_id
- **AND** the user is redirected to the dashboard

#### Scenario: Invalid credentials
- **WHEN** a user submits invalid email or password
- **THEN** the system returns an error: "Invalid email or password"

#### Scenario: Forgot password link
- **WHEN** a user views the login page
- **THEN** a "Forgot your password?" link is displayed below the password field
- **AND** the link navigates to `/reset-password`

### Requirement: Session management
The system SHALL manage user sessions via signed cookies.

#### Scenario: Authenticated request
- **WHEN** a user has an active session
- **THEN** all requests are scoped to their tenant

#### Scenario: Session expiry
- **WHEN** a session has been active for more than 30 days
- **THEN** the session expires and the user must log in again

### Requirement: Tenant-scoped authentication
The system SHALL ensure users can only access their own tenant's data.

#### Scenario: Cross-tenant access attempt
- **WHEN** a user tries to access resources from another tenant
- **THEN** the system returns a 403 Forbidden error

### Requirement: Password hashing
The system SHALL hash passwords using bcrypt before storage.

#### Scenario: Password stored securely
- **WHEN** a user registers or changes password
- **THEN** the password is stored as a bcrypt hash, not plaintext
