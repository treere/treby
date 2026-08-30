## Context

Fresh tenants have no AvailabilityRules, so Schedule page shows only "No team members have set their availability yet." No ad-hoc fallback. First interview requires pre-configuring weekly availability + examiner assignment, undiscoverable. Friction top issue.

## Goals / Non-Goals

**Goals:** When no eligible examiners (users == []), show ad-hoc picker (date, time, examiner select from tenant members) allowing one-off scheduling without recurring rules; keep existing slot path when rules exist; add helper link to Settings → Availability.

**Non-Goals:** Recurring rules; calendar sync.

## Decisions

- In ScheduleLive.Index mount, also load `fallback_users = Accounts.list_users(tenant.id)` for ad-hoc.
- When `@users == []` render branch shows: empty-state message + ad-hoc form (date input, time input, examiner select) + Book Interview button. Book path computes `start_at_utc` from inputs and calls `Interviews.schedule_interview` with 30m duration, bypassing `Availability.compute_slots`.
- Keep helper link `Set weekly availability → Settings → Availability` non-blocking.

## Risks

- Duplicate scheduling logic → mitigate by reusing `book_interview` helper with same attrs.
