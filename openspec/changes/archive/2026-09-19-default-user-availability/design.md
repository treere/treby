## Context

Treby is a multi-tenant ATS. Availability rules drive interview-slot computation. Today each user configures their own working hours via `SettingsLive.Availability`, with one contiguous block per day, a per-rule timezone, and a 15-minute default buffer. There is no company-wide default, so new tenants and new users start empty and scheduling shows "No team members have set their availability yet" until everyone configures hours individually.

This change adds a company-level default availability template and materializes each new user's availability as a snapshot copy of that template at creation time. It also generalizes the model to multiple disjoint time blocks per day and relocates timezone to the company and user level.

## Goals / Non-Goals

**Goals:**
- Seed a company default availability template at tenant creation (Mon–Fri, 09:00–13:00 and 14:00–18:00) in the company timezone.
- Capture the company timezone from the browser at registration; admin can change it.
- Materialize each new user's availability as a copy of the company template at creation (snapshot), in the user's timezone (default = company timezone).
- Support multiple disjoint time blocks per day.
- Move timezone to company/user level (remove per-rule timezone).
- Remove buffer times.
- Provide an admin-only company availability settings page; keep the user page editing the user's own rules.

**Non-Goals:**
- Live inheritance (runtime indirection) — availability is materialized at creation, not resolved live.
- Retroactively syncing existing users when the company template changes.
- Per-rule or per-window customization beyond day-of-week + start/end + scope.
- Calendar provider changes (out of scope).

## Decisions

### D1: Snapshot-at-creation, not live inheritance

**Decision:** At user creation, copy the company template into the user's own `availability_rules` (scope = `"user"`). The user then owns and edits their copy independently.

**Alternatives considered:**
- Live inheritance (no user rules; resolve to company at compute time) — Simpler storage, but editing becomes ambiguous (does a user edit the company template or a personal override?) and the user explicitly stated the value is set at creation, not toggled at runtime.
- Lazy materialization (create user rules on first edit) — Slightly less write at creation, but adds branching in the edit path.

**Rationale:** Matches the requirement that availability is "set at creation." Company and user sets become independently editable from Settings. Changing the company template later only affects future-created users.

### D2: Timezone at company and user level, not per rule

**Decision:** Add `tenants.timezone` and `users.timezone`. Drop `availability_rules.timezone`. Company rules are interpreted in `tenant.timezone`; user rules in `user.timezone`.

**Rationale:** A company and a user each have exactly one timezone. Per-rule timezone was redundant and error-prone. The registration flow supplies the company timezone from the browser; user timezone defaults to the company timezone and is editable.

### D3: Remove buffer times

**Decision:** Drop `buffer_before` / `buffer_after` columns and all buffer logic in slot generation. No margin is applied around busy periods.

**Rationale:** The user explicitly wants no buffer by default. Removing the fields is cleaner than defaulting to zero and keeps slot generation simpler.

### D4: Multiple disjoint windows per day

**Decision:** Drop the unique index on `(tenant_id, user_id, day_of_week)`. Allow any number of `availability_rules` rows per (owner, day_of_week). Slot generation unions all windows for a day.

**Rationale:** The default template itself needs two windows per weekday (09–13 and 14–18). The existing `Map.new(rules, &{&1.day_of_week, &1})` assumes one window and must be replaced with a per-day list.

### D5: Company-template fallback in slot computation

**Decision:** `compute_slots/4` resolves a user's rules first; if the user has none, it falls back to the company template (`scope = "company"`). If neither exists, it returns an empty slot list (no availability).

**Rationale:** Keeps all callers (schedule, interviews, booking) unchanged while guaranteeing a sensible default. Because rules are materialized at creation, fallback mainly covers legacy/empty cases.

### D6: Admin-only company availability

**Decision:** The company availability settings page and the company timezone are editable only by users with the `admin` role.

**Rationale:** Company working hours and timezone are organization-wide policy; only admins should set them.

## Authorization & Multi-tenant Isolation

- Company availability settings: enforce `role == "admin"` in `SettingsLive.CompanyAvailability` (and any controller/handler).
- Every availability query (user rules, company template) is scoped by `tenant_id`; `user_id` scoping applies to user rules. No cross-tenant leakage.
- User availability settings operate on the current authenticated user only.

## Error Handling

- `compute_slots/4` and `compute_overlapping_slots/4` degrade gracefully: missing rules → empty slot list (existing "no availability" UI message remains correct).
- Timezone resolution: if a tenant/user timezone is missing/null, fall back to `"UTC"` rather than raising.
