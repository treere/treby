## Why

Email shape validation was inconsistent: candidates and invites used `~r/@/` (accepting `a@b`, `a@`, `@b`, even `a b@c`), while users and registration used `~r/^[^\s]+@[^\s]+$/`. A public applicant could submit `a@b`, pass validation, and get a notification email that cannot be delivered.

## What Changes

- Introduce `Treby.Emails` as the single validator: local part, `@`, a domain with at least one dot, no whitespace (`a@b` is rejected).
- Use it for candidate changeset, CSV import row validation, invite changeset, user changeset, and both registration changesets.
- Trim candidate emails before validation so existing whitespace-tolerant duplicate detection keeps working.
- Message: "must be a valid email address".

## Capabilities

### New Capabilities
- `email-validation`: one shared rule for every email field, applied consistently across candidate, invite, registration, and import flows.

### Modified Capabilities
- (none)

## Impact

- Spec: new `openspec/specs/email-validation/spec.md`.
- Code: `lib/treby/emails.ex` (new), `lib/treby/candidates/candidate.ex`, `lib/treby/csv_import/csv_import.ex`, `lib/treby/invites/invite.ex`, `lib/treby/accounts/user.ex`, `lib/treby_web/registration.ex`.
- Tests: `test/treby/emails_test.exs` (new), `test/treby/candidates_test.exs`, `test/treby_web/controllers/registration_test.exs`.
