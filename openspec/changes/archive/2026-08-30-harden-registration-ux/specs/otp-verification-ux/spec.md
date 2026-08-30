## ADDED Requirements

### Requirement: OTP verification UX
The system SHALL provide a hardened OTP verification experience with resend countdown, rate-limit messaging, and paste support on both registration and candidate portal verification pages.

#### Scenario: Resend countdown visible
- **WHEN** a user is on a verification page after a code was sent
- **THEN** a countdown shows when Resend will be available (e.g., "Resend code (available in 59s)")
- **AND** the Resend button is disabled until the countdown reaches 0

#### Scenario: Rate-limit message
- **WHEN** a user triggers a rate-limited resend
- **THEN** the system shows "Try again in {seconds}s"

#### Scenario: Paste support
- **WHEN** a user pastes a 6-digit code
- **THEN** the input is filled with the digits and can be submitted

#### Scenario: Dev mailbox link
- **WHEN** in dev environment
- **THEN** verification pages show an "Open mailbox" link to `/dev/mailbox`
