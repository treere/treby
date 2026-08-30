## Context

Registration OTP leaves product: POST /register → flash "We sent code" → user must find code in /dev/mailbox manually, then POST /register/verify. No countdown, generic rate_limited flash.

## Goals / Non-Goals

**Goals:** Inline OTP guidance with spam hint, 60s resend countdown disabling button, improved rate_limited message with seconds.

**Non-Goals:** Changing OTP generation logic; DB.

## Decisions

- Edit `verify.html.heex` to add `Check your email (including spam)` hint and resend button with `.ResendCountdown` colocated hook that disables for 60s and shows `Resend in 59s` countdown.
- Update `RegistrationController.send_verification_code` rate_limited flash to `Too many attempts — try again in 60 seconds` and redirect to verify with info.
- No backend countdown needed; client-side timer suffices.

## Risks

- JS hook failure disables resend permanently → Mitigation: fallback enable after 60s via setInterval, button initially disabled then enabled.
