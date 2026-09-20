# Email Validation

## Purpose

Define a single, consistent rule for what counts as a valid email address across every form and import, so validation never depends on which screen the address is submitted from.

## Requirements

### Requirement: Single email format rule
The system SHALL validate every email field (candidate create/edit, CSV import, team invite, user registration, and account flows) with one shared rule: a non-empty local part, an `@`, and a domain containing at least one dot, with no whitespace. Addresses without a dotted domain (e.g. `a@b`) SHALL be rejected.

#### Scenario: Valid address accepted
- **WHEN** any form or import receives `first.last@example.com`
- **THEN** validation passes

#### Scenario: Undotted domain rejected
- **WHEN** a candidate, invite, or registration email is `a@b`
- **THEN** validation fails with "must be a valid email address" and no record or email is produced

#### Scenario: Candidate whitespace trimmed
- **WHEN** a candidate email has surrounding whitespace (e.g. `  carol@test.com  `)
- **THEN** the stored value is trimmed and duplicate detection still applies

#### Scenario: Consistent across flows
- **WHEN** the same malformed address is submitted to candidate creation, CSV import, an invite, or registration
- **THEN** all of them reject it using the same shared rule
