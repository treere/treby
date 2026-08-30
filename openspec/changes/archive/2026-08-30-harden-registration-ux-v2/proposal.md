## Why

Registration OTP flow leaves the product: `POST /register` → `Send verification code` → user must open `/dev/mailbox` (or email) to copy `366470`, then `POST /register/verify`. No countdown, no inline guidance, generic `rate_limited` flash. This is the first touchpoint and feels broken.

## What Changes

- Show inline OTP sent state with 60s resend countdown, `Resend code` disabled until countdown.
- Keep OTP in same flow (single page or modal) — do not require navigating to mailbox; surface `Check your email (including spam)` hint.
- Improve `rate_limited` flash to `Too many attempts — try again in X seconds`.

## Capabilities

### New Capabilities
- `otp-verification-ux`: Countdown + inline guidance for OTP.

### Modified Capabilities
- `registration-polish`: OTP step UX improved.

## Impact

- `lib/treby_web/controllers/registration_controller.ex` + `lib/treby_web/live/registration_live` (or equivalent template).
- No DB change.
- i18n keys under `priv/gettext`.
