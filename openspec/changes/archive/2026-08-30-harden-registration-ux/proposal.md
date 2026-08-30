## Why

Registration is the first moment a company meets Treby, but the OTP step forces users to leave the product to fetch a code from email. Live testing at `localhost:4000/register` → `POST /register` → `→ /register/verify` showed the user must `goto /dev/mailbox` (or real inbox), copy a 6-digit code (`366470`), then `goto /register/verify` to paste it — with no hint, timer, or auto-help. The same indirection repeats for candidate portal (`/:slug/portal/login` → `785913`) and team invites (`/invite/:token`). `RegistrationVerification` also rate-limits (`:rate_limited`) without a visible countdown, causing silent `Please wait a moment` errors. First-run friction directly impacts activation.

## What Changes

- Harden the OTP verification UX without changing the security model (6-digit code, 10-minute expiry, Swoosh email):
  - On `/register/verify` and `/:slug/portal/verify`: add a visible resend countdown (e.g., 60s), disable `Resend code` until it expires, and show `Code sent to x@… — check your email (including spam)` helper text.
  - Add a `Copy code` helper in dev (`/dev/mailbox` link when `Mix.env() == :dev`) and a `Didn't receive it?` inline help pointing to mailbox.
  - Preserve the two-step controller flow (`RegistrationController.send_verification_code` → `verify_code`) but surface `rate_limited` as `Try again in {seconds}s` rather than generic flash.
  - Add client-side 6-digit auto-advance inputs (optional polish) and paste support so `366470` pasted in one field fills correctly.
- Keep existing `Registration.email_changeset` validation and `Accounts.email_registered?` duplicate check; no change to tenant slug generation (`Tenants.generate_unique_slug`).

## Capabilities

### New Capabilities
- `otp-verification-ux`: Polished OTP step for registration and candidate/invite verification with countdown, rate-limit messaging, and paste-friendly inputs.

### Modified Capabilities
- `registration-polish`: Extend verification code step requirements to include countdown, rate-limit feedback, and dev mailbox discoverability.
- `email-verification`: Clarify that the verification page SHALL display resend timing and SHALL not require the user to guess mailbox location.
- `candidate-otp-auth`: Apply the same countdown/paste UX to `/:slug/portal/verify`.

## Impact

- Affected code: `lib/treby_web/controllers/registration_controller.ex`, `lib/treby_web/controllers/registration_html/verify.html.heex`, `lib/treby_web/controllers/candidate_otp_controller.ex`, `lib/treby/candidate_portal/candidate_portal.ex`, `lib/treby/registration_verification/registration_verification.ex`, `assets/js` hooks for OTP inputs
- No schema migration. No new dependencies.
- Docs: update `site/getting-started.md` to mention verification step and mailbox location for self-hosters.
- Tests: extend `test/treby_web/controllers/registration_test.exs` to assert rate-limit flash with countdown and add LiveView/browser test for paste behavior.
