# Email Verification

## Purpose

Verify that an email address is valid and receives mail before a company account is created, using a 6-digit one-time code sent to the address.

## Requirements

### Requirement: Email OTP sending
The system SHALL allow a prospective registrant to request a verification code for an email address. Before sending, the system SHALL validate the email format and SHALL reject addresses already registered. The system SHALL enforce a resend cooldown per email.

#### Scenario: Request verification code
- **WHEN** a user submits a well-formed email on the registration email step
- **THEN** a 6-digit code is generated, hashed, and stored with a 10-minute expiry
- **AND** the code is sent to the email address
- **AND** the user is taken to the verification code entry page

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
- **AND** the user must wait for the cooldown to expire

#### Scenario: Resend after cooldown
- **WHEN** a user requests a new code more than 60 seconds after the previous request
- **THEN** a new code is generated and sent
- **AND** the previous pending code is invalidated

### Requirement: Email OTP verification
The system SHALL verify a submitted code against the stored hash for the pending email. Verification SHALL fail on expired codes and SHALL limit attempts per code.

#### Scenario: Successful verification
- **WHEN** a user submits the correct code within 10 minutes of issuance
- **THEN** the email is marked as verified in the session
- **AND** the user proceeds to the full registration form with the email pre-filled and locked

#### Scenario: Incorrect code
- **WHEN** a user submits a code that does not match the stored hash
- **THEN** an error is shown
- **AND** the attempt count for the code is incremented

#### Scenario: Too many attempts
- **WHEN** a user submits 5 incorrect codes
- **THEN** further attempts are rejected
- **AND** the user must request a new code

#### Scenario: Expired code
- **WHEN** a user submits a code more than 10 minutes after issuance
- **THEN** verification fails
- **AND** the user must request a new code

### Requirement: Verified email scoping
The system SHALL create the account only for the email verified in the session, never from client-supplied input, and SHALL clear the verified email after account creation.

#### Scenario: Registration uses verified email
- **WHEN** a user completes the full registration form
- **THEN** the account email is taken from the verified email in the session, not from the form
- **AND** the verified email is cleared from the session

#### Scenario: Registration without verified email
- **WHEN** a user attempts the full registration form without a verified email in the session
- **THEN** the user is redirected to the email step