## ADDED Requirements

### Requirement: OTP endpoint throttling
The system SHALL throttle portal OTP request and verify endpoints per IP address and per email, in addition to the existing 60-second per-candidate resend cooldown, to prevent email bombing and code guessing at scale.

#### Scenario: OTP requests throttled per IP
- **WHEN** more than 5 OTP requests originate from the same IP within one minute
- **THEN** further requests are rejected with a "too many requests, retry later" message and no email is sent

#### Scenario: OTP requests throttled per email
- **WHEN** more than 5 OTP requests target the same email within one hour
- **THEN** further requests for that email are rejected until the window passes, regardless of source IP

#### Scenario: Cooldown preserved under throttle
- **WHEN** a request is within throttle limits but inside the 60-second per-candidate cooldown
- **THEN** the existing cooldown behavior applies (no new code, cooldown hint shown)
