## 1. Database

- [x] 1.1 Create migration for `password_reset_tokens` table with columns: `id` (binary_id), `token_hash` (string, unique index), `user_id` (references users), `expires_at` (utc_datetime), `used_at` (utc_datetime, nullable), `inserted_at` (utc_datetime)
- [x] 1.2 Run migration

## 2. Schema & Context

- [x] 2.1 Create `Treby.Accounts.PasswordResetToken` schema module with fields and changeset
- [x] 2.2 Add `generate_reset_token/1` to `Treby.Accounts` — generates token, stores SHA-256 hash, associates with user, sets 1-hour expiry
- [x] 2.3 Add `get_user_by_reset_token/1` to `Treby.Accounts` — looks up token by SHA-256 hash, validates not expired and not used, returns associated user
- [x] 2.4 Add `reset_password/2` to `Treby.Accounts` — updates user password via changeset, marks token as used
- [x] 2.5 Add `delete_expired_reset_tokens/0` cleanup function (tokens older than 24 hours)

## 3. Email

- [x] 3.1 Create `Treby.PasswordResetEmail` module with `reset_email(user, reset_url)` function
- [x] 3.2 Email sends from `{"Treby", "noreply@treby.app"}` with HTML and text body containing the reset link

## 4. Controller & Routes

- [x] 4.1 Add public routes in router: `GET /reset-password` (request form), `POST /reset-password` (submit request), `GET /reset-password/:token` (reset form), `POST /reset-password/:token` (submit new password)
- [x] 4.2 Create `PasswordResetController` with `new` (show request form), `create` (handle request), `edit` (show reset form), `update` (handle password reset)
- [x] 4.3 `create` action: generate token, send email, always show same confirmation message (user enumeration prevention)
- [x] 4.4 `edit` action: validate token, redirect with error if invalid/expired/used
- [x] 4.5 `update` action: validate token + password length, update password, mark token used, redirect to login with success

## 5. Templates

- [x] 5.1 Create request form template (`reset_password_html/new.html.heex`) with email input and submit button
- [x] 5.2 Create reset form template (`reset_password_html/edit.html.heex`) with password input and submit button
- [x] 5.3 Add "Forgot your password?" link to login page template (`session_html/new.html.heex`)

## 6. Testing

- [x] 6.1 Test token generation and storage (hash is stored, raw token is not)
- [x] 6.2 Test token expiry (expired tokens are rejected)
- [x] 6.3 Test token single-use (used tokens are rejected)
- [x] 6.4 Test password reset flow end-to-end (request → email → reset → login)
- [x] 6.5 Test user enumeration prevention (same response for existing and non-existing emails)
- [x] 6.6 Test validation errors (empty email, short password, invalid token)
