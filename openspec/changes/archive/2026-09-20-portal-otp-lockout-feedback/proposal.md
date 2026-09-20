## Why

The candidate portal already stores an `attempts` counter on each OTP, but a wrong code never incremented it (the lookup matched the submitted code's hash, so only the correct-but-expired code counted). As a result the 5-attempt lock never triggered and a candidate could guess codes indefinitely, with no "too many attempts" feedback. Separately, the verify page only rendered the `:rate_limit` flash, so all other errors (invalid code, resend cooldown) were invisible.

## What Changes

- Count every failed verification attempt against the candidate's latest pending OTP, regardless of the submitted code (mirrors `RegistrationVerification`).
- After the 5th failed attempt, invalidate that OTP and show a dedicated message "Too many attempts. Request a new code." instead of the generic invalid-code error.
- Render the generic `:error`/`:info` flash on the portal verify page so error feedback is actually visible.
- No DB or route changes.

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `candidate-otp-auth`: `Candidate verifies OTP` — clarify that any wrong code increments the attempt counter, that the 5th failure invalidates the code with a dedicated prompt, and that the verify page renders the error.

## Impact

- Spec: `openspec/specs/candidate-otp-auth/spec.md`.
- Code: `lib/treby/candidate_portal/candidate_portal.ex` (`verify_otp/2`, `record_failed_otp_attempt/1`), `lib/treby_web/controllers/candidate_otp_controller.ex` (reason-specific flash), `lib/treby_web/live/candidate_portal_live/verify.ex` (flash rendering).
- Tests: `test/treby/candidate_portal_test.exs`, `test/treby_web/integration/candidate_otp_flow_test.exs`.
- Docs: `site/features/candidate-portal.md` (mention lockout), if present.
