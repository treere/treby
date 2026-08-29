## 1. Wrap Auth Templates

- [x] 1.1 Wrap all strings in `registration_html/new.html.heex` with `gettext()` (heading, subtitle, sign-in link, email label, placeholder, submit button)
- [x] 1.2 Wrap all strings in `registration_html/verify.html.heex` with `gettext()` (heading, subtitle, code label, submit button, resend link, "use a different email" link)
- [x] 1.3 Wrap all strings in `registration_html/setup.html.heex` with `gettext()` (heading, email verified subtitle, all field labels/placeholders, ToS/privacy links text, submit button)
- [x] 1.4 Wrap all strings in `session_html/new.html.heex` with `gettext()` (heading, create-account link, email/password labels and placeholders, forgot-password link, sign in button)
- [x] 1.5 Wrap all strings in `password_reset_html/new.html.heex` with `gettext()` (heading, subtitle, email label/placeholder, send reset link button, back-to-sign-in link)
- [x] 1.6 Wrap all strings in `password_reset_html/edit.html.heex` with `gettext()` (heading, password fields, submit button)
- [x] 1.7 Wrap all strings in `invite_html/show.html.heex` with `gettext()` (heading, invitation text, field labels, accept button) while keeping tenant name dynamic

## 2. Wrap Controller Flash Messages

- [x] 2.1 Wrap flash messages in `registration_controller.ex` with `gettext()` (including interpolated "We sent a verification code to %{email}")
- [x] 2.2 Wrap flash messages in `session_controller.ex` with `gettext()` (welcome back, invalid credentials, logged out)
- [x] 2.3 Wrap flash messages in `password_reset_controller.ex` with `gettext()`, moving `gettext()` to the source of dynamic `message` variables (D3)
- [x] 2.4 Wrap flash messages in `invite_controller.ex` with `gettext()` (including interpolated "Welcome to %{name}!")
- [x] 2.5 Wrap flash messages in `candidate_otp_controller.ex` with `gettext()`
- [x] 2.6 Wrap flash messages in `google_auth_controller.ex` with `gettext()`

## 3. Extract and Translate

- [x] 3.1 Run `mix gettext.extract` to regenerate catalogs
- [x] 3.2 Run `mix gettext.merge priv/gettext` to sync `.po` files
- [x] 3.3 Add Italian `msgstr` for every new `msgid` in `it/LC_MESSAGES/default.po`
- [x] 3.4 Verify `errors.po` has Italian translations for auth-related validation errors; add any missing
- [x] 3.5 Grep auth templates/controllers for any remaining unwrapped literal English user-facing strings

## 4. Verify

- [x] 4.1 Run `mix test` and fix any tests asserting on changed strings
- [x] 4.2 Use Playwright to switch locale to Italian and verify `/register` renders in Italian
- [x] 4.3 Use Playwright to verify `/login`, `/reset-password`, `/register/verify`, and setup step render in Italian
- [x] 4.4 Run `mix precommit` and resolve any pending issues