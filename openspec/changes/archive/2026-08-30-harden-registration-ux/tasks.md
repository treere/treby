## 1. Controller & context

- [x] 1.1 Update `RegistrationVerification` / `CandidatePortal` to expose `resend_available_at` (last_sent_at + 60s) and handle `rate_limited` with `retry_after`
- [x] 1.2 Update `RegistrationController` and `CandidateOtpController` to assign `resend_available_at` and `is_dev` to verification templates and to flash `Try again in {s}s` on `rate_limited`

## 2. UI — verification pages

- [x] 2.1 `registration_html/verify.html.heex` — add helper "Code sent to …", countdown display, disabled Resend with `phx-hook=".ResendCountdown"`, dev mailbox link, paste hook `phx-hook=".OtpPaste"` on the code input
- [x] 2.2 `candidate_portal_live/verify.ex` (or `candidate_otp` HTML) — same countdown/paste/dev link as 2.1
- [x] 2.3 `assets/js/app.js` + `assets/js/hooks/` — implement `.ResendCountdown` (ticks from server timestamp) and `.OtpPaste` (strip non-digits, limit 6, auto-submit on paste of 6 digits)

## 3. Tests

- [x] 3.1 Add/extend `test/treby_web/controllers/registration_test.exs` — assert resend countdown in assigns and `rate_limited` flash contains retry seconds; add LiveView/browser test for paste
- [x] 3.2 Add `test/treby_web/live/candidate_portal_live_test.exs` — portal verify countdown and paste

## 4. Specs & Docs

- [x] 4.1 Ensure `email-verification`, `candidate-otp-auth`, `otp-verification-ux` delta specs are correct
- [x] 4.2 Sync `site/getting-started.md` verification step with mailbox hint

## 5. Final checks

- [x] 5.1 Run `mix test` relevant files, `mix precommit`, `openspec validate --strict`
