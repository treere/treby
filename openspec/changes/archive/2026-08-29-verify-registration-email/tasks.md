## 1. Data layer

- [x] 1.1 Generate migration for `registration_otps` table (email, code, expires_at, attempts, used_at) with unique index on email for pending codes
- [x] 1.2 Create `RegistrationOtp` schema mirroring `CandidateOtp`
- [x] 1.3 Create `RegistrationVerification` context with `generate_code/1` (cooldown, hash, expiry), `verify_code/2` (hash match, expiry, attempts), `invalidate_pending/1`, and expired-row cleanup

## 2. Email delivery

- [x] 2.1 Create `Treby.RegistrationOtpEmail` Swoosh template sending the 6-digit code, delivered via `Treby.Mailer`

## 3. Registration flow (controller + templates)

- [x] 3.1 Add routes: OTP send, verify page, verify submit (keeping `GET /register` for both email step and full form)
- [x] 3.2 Rework `RegistrationController`: `new` renders email step or full form based on session `:verified_email`; email-step submit validates format + `email_registered?` + cooldown, sends code, redirects to verify; verify submit checks the code and sets `:verified_email`; full-form submit creates tenant + user + logs in, clearing `:verified_email`
- [x] 3.3 Split `TrebyWeb.Registration` into email-verification and full-registration changesets
- [x] 3.4 Update `registration_html/new.html.heex` for the email step, verification code entry, and full form with locked verified email

## 4. Tests

- [x] 4.1 Test OTP send: format validation, duplicate email, cooldown, resend invalidation
- [x] 4.2 Test OTP verify: success, incorrect code, too many attempts, expired code
- [x] 4.3 Test registration: full form uses verified email from session, no verified email redirects, tenant+user created, login, session cleared
- [x] 4.4 Run `mix test` and `mix precommit`, fix any issues

## 5. Specs + docs

- [x] 5.1 Verify change against `email-verification` and `authentication` delta specs (run `/opsx-verify-change` before archiving)