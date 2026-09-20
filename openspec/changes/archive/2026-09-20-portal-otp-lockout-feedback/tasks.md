## 1. Implementation

- [x] 1.1 Count every failed attempt in `CandidatePortal.record_failed_otp_attempt/1` and invalidate at 5
- [x] 1.2 Restructure `CandidatePortal.verify_otp/2` to check the latest pending OTP first
- [x] 1.3 Map `:too_many_attempts` to a dedicated flash in `CandidateOtpController.do_verify/5`
- [x] 1.4 Render the generic flash on the verify page

## 2. Tests

- [x] 2.1 Unit: wrong code increments; 5th failure returns `:too_many_attempts` and invalidates
- [x] 2.2 Integration: 5 wrong codes show "Too many attempts", page renders it, real code rejected

## 3. Specs and docs

- [x] 3.1 Apply the delta to `openspec/specs/candidate-otp-auth/spec.md`
- [x] 3.2 Update `site/features/candidate-portal.md` if it documents the login code flow

## 4. Verification

- [x] 4.1 `mix precommit` (or the runnable gates) and `openspec validate --strict`
