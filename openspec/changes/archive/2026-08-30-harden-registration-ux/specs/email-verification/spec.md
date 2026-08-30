## MODIFIED Requirements

### Requirement: Email OTP sending
The system SHALL allow a prospective registrant to request a verification code for an email address. Before sending, the system SHALL validate the email format and SHALL reject addresses already registered. The system SHALL enforce a resend cooldown per email and SHALL surface the cooldown and mailbox location to the user.

#### Scenario: Request verification code
- **WHEN** a user submits a well-formed email on the registration email step
- **THEN** a 6-digit code is generated, hashed, and stored with a 10-minute expiry
- **AND** the code is sent to the email address
- **AND** the user is taken to the verification code entry page
- **AND** the verification page shows "Code sent to <email> — check your email (including spam)" and a resend countdown

#### Scenario: Invalid email format
- **WHEN** a user submits an email that fails format validation (e.g., missing `@`, contains spaces)
- **THEN** no code is sent
- **AND** an inline error is shown on the email field

#### Scenario: Email already registered
- **WHEN** a user submits an email that already belongs to an existing user
- **THEN** no code is sent
- **AND** an inline error is shown on the email field: "has already been taken"

#### Scenario: Resend before cooldown
- **WHEN** a user requests a new code less than 60 seconds after the previous request for the same email
- **THEN** the request is rejected
- **AND** the system shows "Try again in {seconds}s" and the Resend button remains disabled until the countdown expires

#### Scenario: Resend after cooldown
- **WHEN** a user requests a new code more than 60 seconds after the previous request
- **THEN** a new code is generated and sent
- **AND** the previous pending code is invalidated
- **AND** the resend countdown resets to 60s

#### Scenario: Dev mailbox affordance
- **WHEN** the app is running in dev and a user is on the verification page
- **THEN** an "Open mailbox" link to `/dev/mailbox` is shown
