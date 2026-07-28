## Why

The app has three quick-win issues that make it feel like a dev build rather than a production product: the browser tab says "Phoenix Framework", users can lock themselves out by mistyping their password with no confirmation, and the registration form collects candidate PII without Terms of Service consent (GDPR risk for EU users). These are fast fixes with high visible impact.

## What Changes

- Remove the "Phoenix Framework" suffix from the browser tab title, showing only "Treby" or the page-specific title
- Add a password confirmation field to the registration form that must match the password
- Add a Terms of Service / Privacy Policy checkbox to the registration form that must be checked to proceed

## Capabilities

### New Capabilities

- `registration-polish`: Password confirmation validation and Terms of Service consent on user registration

### Modified Capabilities

- `authentication`: Registration requirement now includes password confirmation match and ToS acceptance

## Impact

- `lib/treby_web/components/layouts/root.html.heex` — page title suffix change
- `lib/treby_web/live/registration_live.ex` (or equivalent) — form fields and validation
- `lib/treby/accounts/user.ex` — changeset may need ToS field (or handled at LiveView level)
- No database migration needed if ToS acceptance is validated at form level only (not stored)
