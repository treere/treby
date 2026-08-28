# Candidate OTP Authentication

## Purpose

Let candidates access the candidate portal via a one-time password (OTP) sent by email, providing secure, passwordless authentication without email enumeration.

## Requirements

### Requirement: Candidate requests OTP login
The system SHALL allow a candidate to request access to the portal by entering their email address at `/:tenant_slug/portal/login`, sending a one-time code (OTP) to that email address.

#### Scenario: Email exists in system
- **WHEN** a candidate enters an email that matches an existing candidate record in the tenant
- **THEN** the system generates a 6-digit numeric code, stores its SHA-256 hash in `candidate_otps` with a 10-minute expiry, and sends an email containing the code to the candidate's address

#### Scenario: Email does not exist
- **WHEN** a candidate enters an email that does not match any candidate record in the tenant
- **THEN** the system displays the same success message as for existing emails ("Check your email for your login code") to prevent email enumeration

#### Scenario: Repeated requests rate limited
- **WHEN** a candidate requests a code more than once within 60 seconds
- **THEN** the system does not send a new code and displays the generic success message

#### Scenario: Multiple pending codes invalidated
- **WHEN** a candidate requests a new code while a previous one is still pending
- **THEN** the previous pending code is invalidated before the new one is created

### Requirement: Candidate verifies OTP
The system SHALL verify the code entered by the candidate against the stored OTP and create an authenticated session on success.

#### Scenario: Valid code
- **WHEN** a candidate enters the correct, unused, non-expired code
- **THEN** the system creates a session (candidate_id, candidate_tenant_id, expiry timestamp), invalidates all pending codes for that candidate, and redirects to `/:tenant_slug/portal`

#### Scenario: Invalid code
- **WHEN** a candidate enters a code that does not match any stored pending code
- **THEN** the system increments the attempt counter and displays a generic "invalid or expired code" error

#### Scenario: Expired code
- **WHEN** a candidate enters a code older than 10 minutes
- **THEN** the system treats it as invalid and prompts the candidate to request a new code

#### Scenario: Too many attempts
- **WHEN** a candidate reaches 5 failed verification attempts for a pending code
- **THEN** the system invalidates that code and prompts the candidate to request a new one

#### Scenario: Code for different candidate
- **WHEN** a code does not match the email used to request it
- **THEN** the system displays the generic "invalid or expired code" error

### Requirement: Candidate OTP email content
The system SHALL send OTP emails with a clear, concise format containing the code and a link to the verification page.

#### Scenario: Email format
- **WHEN** an OTP email is sent
- **THEN** the email subject is "Your login code" and the body contains a greeting with the candidate name, the 6-digit code, the expiry note (10 minutes), and a link to `/:tenant_slug/portal/verify`

### Requirement: Candidate session management
The system SHALL maintain candidate sessions via signed cookies with a limited lifetime.

#### Scenario: Session creation
- **WHEN** a candidate successfully verifies an OTP
- **THEN** the system stores `candidate_id`, `candidate_tenant_id`, and a session expiry timestamp (default 4 hours, configurable) in the session

#### Scenario: Session validation
- **WHEN** a candidate accesses a portal route with a valid session
- **THEN** the system validates the session and loads the candidate and tenant from the database

#### Scenario: Session expiry
- **WHEN** a candidate accesses a portal route with an expired session
- **THEN** the system clears the candidate session and redirects to `/:tenant_slug/portal/login`

### Requirement: Candidate logout
The system SHALL allow a logged-in candidate to end their session explicitly.

#### Scenario: Logout from portal
- **WHEN** a candidate clicks "Logout" in the portal
- **THEN** the system clears the candidate session and redirects to `/:tenant_slug/portal/login`

#### Scenario: Portal routes after logout
- **WHEN** a logged-out candidate navigates to a portal route
- **THEN** the system redirects them to `/:tenant_slug/portal/login`