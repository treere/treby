## MODIFIED Requirements

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
