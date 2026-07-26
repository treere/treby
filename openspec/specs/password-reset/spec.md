# Password Reset

## Purpose

Allow users to recover access to their account by resetting their password via email.

## Requirements

### Requirement: Password reset request
The system SHALL allow users to request a password reset by providing their email address.

#### Scenario: Valid email submitted
- **WHEN** a user submits a valid email address on the reset request form
- **THEN** the system generates a single-use, time-limited reset token
- **AND** sends a password reset email containing a link with the token
- **AND** displays a confirmation message: "If an account exists with that email, you'll receive a reset link shortly"

#### Scenario: Non-existent email submitted
- **WHEN** a user submits an email that does not exist in the system
- **THEN** the system displays the same confirmation message as for a valid email
- **AND** no email is sent
- **AND** the system does not reveal whether the email exists

#### Scenario: Empty email submitted
- **WHEN** a user submits the reset form with an empty email field
- **THEN** the system returns a validation error: "Email is required"

### Requirement: Reset token generation
The system SHALL generate cryptographically secure reset tokens.

#### Scenario: Token format
- **WHEN** a reset token is generated
- **THEN** it SHALL be 32 bytes of random data, encoded as URL-safe base64 without padding
- **AND** the SHA-256 hash of the token SHALL be stored in the `password_reset_tokens` table
- **AND** the raw token SHALL NOT be stored

#### Scenario: Token expiry
- **WHEN** a reset token is generated
- **THEN** it SHALL expire after 1 hour from creation

#### Scenario: Token associations
- **WHEN** a reset token is generated
- **THEN** it SHALL be associated with the requesting user's ID
- **AND** have a `used_at` field set to NULL

### Requirement: Password reset email
The system SHALL send a password reset email when a valid reset is requested.

#### Scenario: Email content
- **WHEN** a reset email is sent
- **THEN** it SHALL contain a link in the format `/reset-password/:token`
- **AND** the link SHALL be clickable and correctly formatted
- **AND** the email SHALL be sent from `{"Treby", "noreply@treby.app"}`

### Requirement: Password reset form
The system SHALL provide a form for users to set a new password via the reset link.

#### Scenario: Valid token access
- **WHEN** a user navigates to `/reset-password/:token` with a valid, unused, unexpired token
- **THEN** the system renders a form with a "New password" field

#### Scenario: Invalid token access
- **WHEN** a user navigates to `/reset-password/:token` with a token that does not exist
- **THEN** the system redirects to `/reset-password` with an error flash: "Invalid or expired reset link"

#### Scenario: Expired token access
- **WHEN** a user navigates to `/reset-password/:token` with a token that has expired
- **THEN** the system redirects to `/reset-password` with an error flash: "Invalid or expired reset link"

#### Scenario: Already-used token access
- **WHEN** a user navigates to `/reset-password/:token` with a token that has already been used
- **THEN** the system redirects to `/reset-password` with an error flash: "Invalid or expired reset link"

### Requirement: Password update via reset
The system SHALL allow users to update their password using a valid reset token.

#### Scenario: Successful password reset
- **WHEN** a user submits the reset form with a valid token and a password of 6+ characters
- **THEN** the user's password is updated (bcrypt-hashed)
- **AND** the token is marked as used (`used_at` set to current timestamp)
- **AND** the user is redirected to `/login` with a success flash: "Password has been reset. Please sign in."

#### Scenario: Password too short
- **WHEN** a user submits the reset form with a password shorter than 6 characters
- **THEN** the system returns a validation error: "Password must be at least 6 characters"
- **AND** the token remains valid for another attempt

### Requirement: Forgot password link on login page
The system SHALL display a "Forgot your password?" link on the login page.

#### Scenario: Link visibility
- **WHEN** a user views the login page
- **THEN** a "Forgot your password?" link is visible below the password field
- **AND** the link navigates to `/reset-password`
