## MODIFIED Requirements

### Requirement: Candidate verifies OTP
The system SHALL verify the code entered by the candidate against the stored OTP and create an authenticated session on success, with clear expiry, typo-recovery, and lockout guidance.

#### Scenario: Valid code
- **WHEN** a candidate enters the correct, unused, non-expired code
- **THEN** the system creates a session (candidate_id, candidate_tenant_id, expiry timestamp), invalidates all pending codes for that candidate, and redirects to `/:tenant_slug/portal`

#### Scenario: Invalid code
- **WHEN** a candidate enters a code that does not match the pending code (or no pending code exists)
- **THEN** the system increments the attempt counter for that candidate's pending code and displays a generic "invalid or expired code" error on the verify page, with a link "Didn't receive it? Check spam or correct your email" back to `/portal/login`

#### Scenario: Expired code
- **WHEN** a candidate enters a code older than 10 minutes
- **THEN** the system treats it as invalid and prompts the candidate to request a new code, re-showing the 10-min expiry hint

#### Scenario: Too many attempts
- **WHEN** a candidate reaches 5 failed verification attempts for a pending code
- **THEN** the system invalidates that code and shows "Too many attempts. Request a new code." on the verify page so the candidate knows to resend

#### Scenario: Code for different candidate
- **WHEN** a code does not match the email used to request it
- **THEN** the system displays the generic "invalid or expired code" error
