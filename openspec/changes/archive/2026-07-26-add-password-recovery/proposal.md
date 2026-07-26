## Why

Users who forget their password have no self-service recovery path. There is no "Forgot Password" link on the login page and no password reset functionality in the codebase. If a user loses access to their password, they are permanently locked out unless a developer manually intervenes. This is a critical account safety gap that must be resolved before launch.

## What Changes

- Add a "Forgot Password?" link on the login page
- Add a `/reset-password` page where users enter their email to request a reset
- Generate a time-limited, single-use reset token and store it (hashed) in a new `password_reset_tokens` table
- Send a password reset email with a link containing the token
- Add a `/reset-password/:token` page where users enter a new password
- Validate the token (existence, expiry, single-use) before allowing the password update
- Update the existing `authentication` spec with new password-reset requirements

## Capabilities

### New Capabilities
- `password-reset`: The full password recovery flow — request page, token generation, email delivery, reset form, and token validation

### Modified Capabilities
- `authentication`: Add requirement for "Forgot Password" link on login page and password reset as part of the auth lifecycle

## Impact

- **Database**: New `password_reset_tokens` table (token_hash, user_id, expires_at, used_at)
- **Accounts context**: New functions for generating reset tokens, validating them, and updating passwords
- **Email**: New `PasswordResetEmail` module using existing Swoosh infrastructure
- **Router**: Two new public routes (`/reset-password` GET/POST, `/reset-password/:token` GET/POST)
- **Login template**: Add "Forgot Password?" link
- **Dependencies**: None new — uses existing Bcrypt, Swoosh, and `:crypto` token generation
