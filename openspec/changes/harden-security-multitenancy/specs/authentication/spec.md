## ADDED Requirements

### Requirement: Login rate limiting
The system SHALL throttle staff login attempts per IP address and per email to slow credential-stuffing and brute-force attacks, without changing successful-login behavior.

#### Scenario: Excessive attempts from one IP are rejected
- **WHEN** more than 5 login attempts originate from the same IP within one minute
- **THEN** further attempts receive HTTP 429 with a localized "too many requests, retry later" message instead of hitting credential verification

#### Scenario: Excessive attempts for one email are rejected
- **WHEN** more than 10 login attempts target the same email within one hour
- **THEN** further attempts for that email are rejected with HTTP 429 until the window passes
- **AND** attempts for other emails are unaffected
