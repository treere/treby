# Candidate Magic Link

## Purpose

Authenticate candidates into the candidate portal via a passwordless magic link flow, providing secure access without requiring candidates to create accounts.

## Requirements

### Requirement: Candidate requests magic link
The system SHALL display a form at `/:tenant_slug/portal` where candidates enter their email address to request a magic link.

#### Scenario: Email exists in system
- **WHEN** candidate enters an email that matches an existing candidate record in the tenant
- **THEN** the system generates a unique token, stores it in `candidate_tokens` with a 15-minute expiry, and sends an email containing the magic link to the candidate

#### Scenario: Email does not exist
- **WHEN** candidate enters an email that does not match any candidate record in the tenant
- **THEN** the system displays the same success message as for existing emails ("Check your email") to prevent email enumeration

#### Scenario: Token generation
- **WHEN** a magic link is requested
- **THEN** the system generates a cryptographically random 32-byte token, stores the SHA-256 hash in `candidate_tokens.token`, and includes the raw token in the email link URL

### Requirement: Candidate authenticates via magic link
The system SHALL authenticate candidates via a magic link at `/:tenant_slug/c/:token`.

#### Scenario: Valid token
- **WHEN** candidate clicks a magic link with a valid, unused, non-expired token
- **THEN** the system creates a session cookie (signed, 24-hour expiry) and redirects to `/:tenant_slug/portal`

#### Scenario: Expired token
- **WHEN** candidate clicks a magic link with a token that has expired (older than 15 minutes)
- **THEN** the system displays "This link has expired. Please request a new one." with a link back to the magic link request page

#### Scenario: Already used token
- **WHEN** candidate clicks a magic link with a token that has already been used (`used_at` is not null)
- **THEN** the system displays "This link has already been used. Please request a new one." with a link back to the magic link request page

#### Scenario: Invalid token
- **WHEN** candidate clicks a magic link with a token that does not exist in the database
- **THEN** the system displays "Invalid link. Please request a new one." with a link back to the magic link request page

### Requirement: Candidate session management
The system SHALL maintain candidate sessions via signed cookies.

#### Scenario: Session creation
- **WHEN** candidate authenticates via valid magic link
- **THEN** the system stores `candidate_id` and `candidate_tenant_id` in a signed session cookie with 24-hour expiry

#### Scenario: Session validation
- **WHEN** candidate accesses a portal route
- **THEN** the system validates the session cookie and loads the candidate and tenant from the database

#### Scenario: Session expiry
- **WHEN** candidate accesses a portal route with an expired session
- **THEN** the system redirects to the magic link request page at `/:tenant_slug/portal`

### Requirement: Magic link email content
The system SHALL send magic link emails with a clear, concise format.

#### Scenario: Email format
- **WHEN** a magic link email is sent
- **THEN** the email subject is "Access your application portal" and the body contains a greeting with the candidate name, a single sentence explaining the link, and a prominent "Access Portal" button linking to `/:tenant_slug/c/:token`
