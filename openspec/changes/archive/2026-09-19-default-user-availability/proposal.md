## Why

Treby's availability system supports only one contiguous block per day and has no company-level default. Every new user starts with no availability, so interview scheduling shows "No team members have set their availability yet" until each person manually configures their hours. Timezone is configured per availability rule rather than per company/user, and there is no company-wide working-hours template.

This change introduces a company-level default availability template (seeded at registration from the browser timezone) and per-user availability that is materialized as a copy at user-creation time, with support for multiple disjoint time blocks per day and timezone set at company and user level.

## What Changes

- Add company-level default availability rules (template) seeded when a tenant is created; default Mon–Fri 09:00–13:00 and 14:00–18:00 in the company timezone.
- Company timezone is set at registration from the browser timezone and is editable by admin only.
- Each new user gets their own availability rules materialized as a copy of the company template at creation time (snapshot), with the user's timezone (default = company timezone).
- Support multiple disjoint time blocks per day (drop the one-rule-per-day constraint).
- Move timezone from per-availability-rule to per-company (tenant) and per-user; remove per-slot timezone.
- Remove buffer times entirely (no buffer before/after interviews).
- Add a company availability settings page (admin-only); update the user availability settings page to edit the user's own rules and timezone.
- Slot computation (`compute_slots/4`, `compute_overlapping_slots/4`) rewritten to union multiple windows per day and resolve user rules with a company-template fallback.

## Capabilities

### New Capabilities

- `company-availability`: Company-level default availability template (working-hours windows + company timezone) with CRUD and admin-only editing; seeded at tenant creation.

### Modified Capabilities

- `availability-rules`: Multiple disjoint time blocks per day; timezone at company/user level (not per rule); no buffer; resolution falls back to the company template when a user has no rules; user rules are materialized at creation from the company template.

## Impact

- **New dependencies**: none.
- **Database migrations** (no data preservation required — existing data may be reset/dropped):
  - `tenants`: add `timezone` column (string, default `"UTC"`).
  - `users`: add `timezone` column (string, default `"UTC"`).
  - `availability_rules`: drop the unique index on `(tenant_id, user_id, day_of_week)`; add `scope` column (`"company"` | `"user"`); make `user_id` nullable (NULL for company rules); drop `timezone` column; drop `buffer_before` / `buffer_after` columns.
- **New routes**: `/app/settings/company-availability` (admin-only).
- **Modified modules under `lib/treby/` and `lib/treby_web/`**:
  - `Treby.Tenants` — `create_tenant/1` accepts `timezone` and seeds the company template (10 rules: Mon–Fri × {09:00–13:00, 14:00–18:00}).
  - `Treby.Accounts` — `create_user/1` sets `user.timezone` (default = tenant timezone) and seeds the user's own rules as a copy of the company template.
  - `Treby.Availability` — `compute_slots/4`, `compute_overlapping_slots/4`, rule listing, resolution helper.
  - `Treby.Availability.AvailabilityRule` — changeset: `scope`, nullable `user_id`, no `timezone`/buffer fields.
  - `TrebyWeb.RegistrationController` — pass browser timezone to `create_tenant/1`.
  - Registration HTML/JS — capture `Intl.DateTimeFormat().resolvedOptions().timeZone` into a hidden field.
  - `TrebyWeb.SettingsLive.Availability` — user rules + user timezone, multiple windows per day.
  - `TrebyWeb.SettingsLive.CompanyAvailability` (new, admin-only) — company template + company timezone.
- **External APIs**: none.
