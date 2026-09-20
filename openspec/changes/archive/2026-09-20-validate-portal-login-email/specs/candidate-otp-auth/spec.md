## ADDED Requirements

### Requirement: Portal login requires a non-blank email
The system SHALL reject a portal login request whose email is missing or blank (empty or whitespace) before any lookup, sending no code and never raising a server error.

#### Scenario: Missing email field
- **WHEN** a client posts to `/:tenant_slug/portal/login` without an `email` parameter
- **THEN** the request redirects to `/portal/login` with the error "Please enter your email address"
- **AND** no code is generated or sent

#### Scenario: Blank email
- **WHEN** a client posts an empty or whitespace-only email
- **THEN** the request redirects to `/portal/login` with the error "Please enter your email address"
- **AND** no candidate lookup happens and no code is sent

#### Scenario: Verify without a session email
- **WHEN** a client posts a code to `/:tenant_slug/portal/verify` without a pending email in the session
- **THEN** the request redirects to `/portal/login` with the error "Please enter your email address"
