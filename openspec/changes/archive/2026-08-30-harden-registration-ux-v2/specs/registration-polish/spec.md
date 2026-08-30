## ADDED Requirements

### Requirement: Registration OTP verification

The system SHALL verify email via OTP with clear inline guidance and resend throttling UX.

#### Scenario: OTP sent shows spam hint and countdown

- **WHEN** a user requests a verification code
- **THEN** the verify page shows `Check your email (including spam)` hint
- **AND** the `Resend code` button is disabled for 60s with countdown `Resend in Xs`

#### Scenario: Rate limited shows seconds

- **WHEN** a user hits rate limit for OTP resend
- **THEN** the flash says `Too many attempts — try again in 60 seconds`
