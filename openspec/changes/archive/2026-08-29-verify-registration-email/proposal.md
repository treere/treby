## Why

Company registration currently logs the user in immediately after creating a tenant + admin user, with no proof the email is valid or receives mail. Typos like `gmail.con` and fake inboxes produce real accounts that can never be recovered (password reset links go to that same email) and create ghost tenants.

## What Changes

- Registration becomes a three-step flow: **email → OTP verification → full registration form → account creation**. The email is verified via a 6-digit one-time code sent by email *before* any tenant or user is created.
- Only the verified email is carried between steps (stored in the session). No form data (password, company name) is held across steps; the full form is filled after verification, with the verified email pre-filled and locked.
- A new `registration_otps` table stores hashed codes with expiry, attempt count, and used flag (mirrors the existing `candidate_otps` pattern).
- Abuse controls: per-email resend cooldown, attempt limit, code expiry, and basic format validation before an OTP is ever sent.
- New Swoosh email template for the registration OTP.
- No account is created until the email is verified, eliminating invalid registrations and unconfirmed-user state.

## Capabilities

### New Capabilities
- `email-verification`: Email OTP verification during company registration — sending codes, verifying codes, and abuse controls (cooldown, attempts, expiry).

### Modified Capabilities
- `authentication`: The "User registration" requirement changes — a valid email must be verified via OTP before the user (and tenant) is created and the user is logged in.

## Impact

- `lib/treby_web/controllers/registration_controller.ex` — restructured into email/verify/register steps
- `lib/treby_web/registration.ex` — split into email-verification and registration changesets
- `lib/treby_web/router.ex` — routes for OTP send/verify
- `lib/treby_web/controllers/registration_html/new.html.heex` — multi-step templates
- New `lib/treby/registration_otp` schema/context (mirrors `candidate_otp`), new migration
- New Swoosh email module/template for the OTP delivery
- `Treby.Accounts.email_registered?/1` reused for the duplicate check at the email step
- Tests for the registration controller and OTP verification
- Ops note: email delivery must be configured in production for the flow to complete