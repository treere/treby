## 1. Validator

- [x] 1.1 Add `Treby.Emails` with `valid?/1` and `validate_format/2`

## 2. Adoption

- [x] 2.1 Candidate changeset: trim + shared validator
- [x] 2.2 CSV import row validation
- [x] 2.3 Invite changeset
- [x] 2.4 User and registration changesets

## 3. Tests

- [x] 3.1 Validator unit tests (valid, undotted, malformed, non-binary)
- [x] 3.2 Candidate rejects `a@b`; whitespace still dedupes
- [x] 3.3 Registration rejects `a@b` with the shared message

## 4. Verification

- [x] 4.1 Runnable gates and `openspec validate --strict`
