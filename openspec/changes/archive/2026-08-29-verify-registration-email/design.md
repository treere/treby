## Context

Registration (`TrebyWeb.RegistrationController.create/2`) creates a tenant + admin user and logs them in immediately. Email is validated only by the lax regex `~r/^[^\s]+@[^\s]+$/`. There is no proof the address exists or receives mail, so typos/fake inboxes produce unrecoverable accounts (password reset depends on the email) and ghost tenants.

The codebase already ships an OTP machine for candidates (`Treby.CandidatePortal` + `candidate_otps` table): hashed codes, expiry, attempt limit, resend cooldown, email delivery via Swoosh. Password reset has the same hashed-token pattern (`PasswordResetToken`).

## Goals / Non-Goals

**Goals:**
- Verify email ownership via a 6-digit OTP before any tenant/user is created
- Carry only the verified email between steps (no password or form data held server-side or in session beyond the email)
- Reuse the existing candidate-OTP patterns and Swoosh mailer
- Basic abuse resistance without added complexity

**Non-Goals:**
- MX-lookup / deliverability APIs / disposable-domain blocklists (OTP subsumes these)
- Verifying invited users or Google OAuth users (invite links arrive through the email; Google verifies on its side)
- Re-verification when a user later changes email
- Per-IP rate limiting beyond a single optional counter (deferred)

## Decisions

**D1. Verify email first, then register (email-first flow).**
The registration form is split: step 1 collects only the email; step 2 verifies the OTP; step 3 presents the full form (company name, name, password, confirmation, ToS) with the verified email locked. This avoids holding form data between steps. Alternative rejected: full-form-then-OTP would require stashing the password in session or DB across steps.

**D2. Session holds only `:verified_email`.**
After successful OTP verification, `verified_email` is stored in the encrypted session cookie. The final registration action reads the email from the session, never from client input, so verification cannot be skipped. The email is pre-filled and read-only on the final form. Cleared after account creation.

**D3. New `registration_otps` table mirroring `candidate_otps`.**
Columns: `code` (SHA-256 hash), `expires_at`, `attempts` (default 0), `used_at`, `email`. One pending OTP per email (previous pending codes invalidated on resend). DB-backed cooldown/attempts keep abuse controls server-side (a session-only hash would let users reset the counter by clearing cookies).

**D4. Abuse controls mirror the candidate OTP flow.**
10-minute expiry, 60s resend cooldown, 5 attempt limit. Basic format regex + `email_registered?` check before any OTP is sent. Optional single per-IP send counter, easy to add later.

**D5. Controller-based, not LiveView.**
Auth pages are controller-rendered; the new steps follow that pattern (a `new`/`verify` set of actions). No JS required; step 1 → step 2 → step 3 are separate pages.

**D6. New Swoosh email template** (e.g. `Treby.RegistrationOtpEmail`) sending the 6-digit code, delivered via `Treby.Mailer`, matching the candidate OTP email style.

**D7. Cleanup of expired `registration_otps` rows** via a simple delete-all task mirroring `Accounts.delete_expired_reset_tokens/1` (scheduled or on-demand).

## Risks / Trade-offs

- **Registration now takes 3 steps** → The email step is a single field; OTP entry is quick. Mitigates typos by catching them at the email step.
- **Email delivery is a hard dependency of signup** → If the mailer isn't configured in prod, nobody can register. Mitigation: verify prod Swoosh adapter before shipping; dev uses the mailbox preview.
- **Public OTP endpoint is an email-bombing vector** → Per-email cooldown + attempt limit + format gate. Optional per-IP counter deferred.
- **OTP accumulation in DB** → Expired-row cleanup (D7).
- **Session-based verified email ties verification to a browser** → Acceptable: the flow is a single user's registration; the cookie is encrypted and short-lived.

## Migration Plan

1. Add migration for `registration_otps` (and cleanup task).
2. Add OTP send/verify + email template; keep old single-step `create` temporarily behind no session, or replace in one deploy.
3. Update `RegistrationController`, routes, templates.
4. Update `authentication` registration spec scenarios and add `email-verification` spec.
5. Rollback: revert routes/controller to the old `create`; drop table (or leave unused).

## Open Questions

- Per-IP rate limit: include the simple counter now, or defer? (Leaning defer.)
- Single `POST /register` action branching on session state vs. separate `/register/verify` route for OTP submission. (Design assumes separate route for clarity.)