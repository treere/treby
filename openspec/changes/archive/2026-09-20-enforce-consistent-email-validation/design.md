## Context

Four validators existed with two behaviours. The candidate/invite regex `~r/@/` also accepted whitespace and malformed strings, so the "invalid email" server-side guard was effectively "contains an at-sign".

## Goals / Non-Goals

- Goal: one validator, one rule, used by every email field.
- Goal: reject addresses without a dotted domain (`a@b`) since they are not deliverable.
- Non-goal: full RFC 5322 validation; a pragmatic deliverability check is enough.
- Non-goal: change uniqueness/dedup semantics.

## Decisions

- `Treby.Emails.valid?/1` and `Treby.Emails.validate_format/2` own the regex `~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/`.
- Candidate changeset trims the email (`update_change/3`) before validating, preserving the existing whitespace-tolerant duplicate behaviour and the `lower(trim(email))` unique index.
- CSV import row validation uses `Treby.Emails.valid?/1` instead of `=~ ~r/@/`.

## Risks / Trade-offs

- Rejects `user@localhost`-style addresses; acceptable for a hosted ATS.
- The user/registration message changes from "must have the @ sign and no spaces" to "must be a valid email address"; tests updated.
