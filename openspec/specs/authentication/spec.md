# Authentication

## Purpose

Handle user registration, login, session management, and tenant-scoped access control.

## Requirements

### Requirement: User registration
The system SHALL allow users to register with email, password, password confirmation, and Terms of Service acceptance. The email SHALL be verified via a one-time code before the user (and tenant) is created. The system SHALL use the verified email from the session, never client-supplied input. Email addresses SHALL be treated case-insensitively and SHALL be globally unique across all users. A single identity SHALL have one bcrypt-hashed password shared across all memberships.

#### Scenario: Successful registration (new identity)
- **WHEN** a user has verified their email via a one-time code, that email does not belong to any existing user, and submits the full registration form (company name, name, password, password confirmation matching, and accepts Terms of Service)
- **THEN** a new tenant and a new user are created with the verified email and a bcrypt-hashed password
- **AND** a membership linking the user to the tenant with role "admin" is created
- **AND** the user is logged in automatically and redirected to `/:tenant_slug/app`
- **AND** the verified email is cleared from the session

#### Scenario: Registration attempt with already-registered email
- **WHEN** a user verifies an email that already belongs to an existing user and proceeds to the registration form
- **THEN** the system does not create a new user
- **AND** the user is redirected to login with a message to log in and use "Create new company" to add a workspace

#### Scenario: Password mismatch
- **WHEN** a user submits registration with password and password_confirmation that do not match
- **THEN** the system returns an error: "Passwords do not match"

#### Scenario: Terms of Service not accepted
- **WHEN** a user submits registration without checking the Terms of Service checkbox
- **THEN** the system returns an error: "You must accept the Terms of Service"

#### Scenario: Registration without verified email
- **WHEN** a user attempts the full registration form without having verified their email in the session
- **THEN** the user is redirected to the email verification step

### Requirement: User login
The system SHALL allow users to log in with email and password. The system SHALL authenticate against the globally unique identity and then resolve the user's memberships.

#### Scenario: Successful login with single membership
- **WHEN** a user submits a valid email and password and the user has exactly one membership
- **THEN** a session is created with `user_id` only
- **AND** the user is redirected to `/:tenant_slug/app` for that membership

#### Scenario: Successful login with multiple memberships
- **WHEN** a user submits a valid email and password and the user has two or more memberships
- **THEN** a session is created with `user_id`
- **AND** the user is redirected to `/choose-tenant`
- **AND** after choosing a workspace the user is redirected to `/:tenant_slug/app` for the chosen membership

#### Scenario: Choosing a workspace after login
- **WHEN** a user on `/choose-tenant` selects a workspace they belong to
- **THEN** the system verifies the membership and redirects to `/:tenant_slug/app` for that tenant

#### Scenario: Invalid credentials
- **WHEN** a user submits an invalid email or password
- **THEN** the system returns an error: "Invalid email or password"

#### Scenario: Forgot password link
- **WHEN** a user views the login page
- **THEN** a "Forgot your password?" link is displayed below the password field
- **AND** the link navigates to `/reset-password`

### Requirement: Session management
The system SHALL manage user sessions via signed cookies. The session SHALL store `user_id` only; the active workspace SHALL be derived from the URL slug `/:tenant_slug`.

#### Scenario: Authenticated request
- **WHEN** a user has an active session and navigates to `/:tenant_slug/app/*`
- **THEN** the system loads the tenant by slug, verifies the user has a membership for that tenant, and scopes all requests to that tenant
- **AND** the system assigns `current_user`, `current_tenant`, `current_membership`, and `available_tenants`

#### Scenario: Access to workspace without membership
- **WHEN** an authenticated user tries to access `/:tenant_slug/app/*` for a tenant they do not belong to
- **THEN** the system returns a 403 Forbidden or redirects to `/choose-tenant`

#### Scenario: Session expiry
- **WHEN** a session has been active for more than 30 days
- **THEN** the session expires and the user must log in again

### Requirement: Tenant-scoped authentication
The system SHALL ensure users can only access data for tenants where they hold a membership.

#### Scenario: Cross-tenant access attempt
- **WHEN** a user tries to access resources from a tenant without membership
- **THEN** the system returns a 403 Forbidden error

### Requirement: Password hashing
The system SHALL hash passwords using bcrypt before storage. The password hash SHALL live on the identity and SHALL apply to all memberships.

#### Scenario: Password stored securely
- **WHEN** a user registers or changes password
- **THEN** the password is stored as a bcrypt hash on the user, not plaintext

#### Scenario: Password reset is global
- **WHEN** a user resets their password via `/reset-password`
- **THEN** the new password applies to the single identity and is valid for all memberships

### Requirement: Create additional workspace while authenticated
The system SHALL allow an authenticated user to create a new tenant and become its admin without creating a new identity.

#### Scenario: Create new company from switcher
- **WHEN** an authenticated user submits a new company name via "Create new company"
- **THEN** a new tenant is created with a unique slug
- **AND** a membership with role "admin" linking the current user to the new tenant is created
- **AND** the user is redirected to `/:new_tenant_slug/app`
