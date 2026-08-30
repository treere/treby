## MODIFIED Requirements

### Requirement: Candidate OTP login
The system SHALL allow a candidate to request a login code for their email and verify it to access the portal. The system SHALL enforce a cooldown and paste-friendly entry.

#### Scenario: Request login code
- **WHEN** a candidate submits their email on the portal login page
- **THEN** a 6-digit code is generated and sent
- **AND** the verification page shows a countdown and helper text

#### Scenario: Paste-friendly code entry
- **WHEN** a candidate pastes a 6-digit code into the verification input
- **THEN** the input accepts the digits, strips non-digits, and allows submission without manual per-digit entry

#### Scenario: Resend cooldown in portal
- **WHEN** a candidate requests a new code before the cooldown expires
- **THEN** the system shows "Try again in {seconds}s" and keeps Resend disabled
