## Context

`CandidatePortal.verify_otp/2` looked the OTP up by `candidate_id AND code == hash(submitted)`. A wrong guess returned `nil` -> `:invalid_or_expired`, and `record_failed_otp_attempt/2` looked up the same way, so a wrong guess never incremented `attempts`. The `attempts >= 5` guard was therefore only reachable by re-submitting the correct (but expired/used) code.

## Goals / Non-Goals

- Goal: count any wrong guess against the candidate's latest pending OTP and lock after 5.
- Goal: make the failure visible to the candidate on the verify page.
- Non-goal: change the IP/email throttling buckets or the 60s resend cooldown.
- Non-goal: apply the same message change to the registration OTP flow (its counter already works; its tests assert the generic message).

## Decisions

- `verify_otp/2` now loads `latest_pending_otp(candidate.id)` first: `nil` -> invalid, `attempts >= 5` -> too many, matching hash -> success/expired, mismatch -> invalid.
- `record_failed_otp_attempt/1` (was `/2`, dropped the unused code) increments the latest pending OTP; on reaching 5 it invalidates the pending OTPs and returns `:too_many_attempts`.
- Controller maps `:too_many_attempts` (both from `verify_otp` and from `record_failed_otp_attempt`) to "Too many attempts. Request a new code.".
- `verify.ex` renders `<Layouts.flash_group flash={@flash} />`; the existing `:rate_limit` box is kept.

## Risks / Trade-offs

- A wrong guess now consumes an attempt even if the submitted code has no matching row — intended.
- After lockout the candidate must request a new code; the resend path already exists and is rate limited.
