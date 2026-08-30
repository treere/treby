## Context

`ScheduleLive.Index` (`/app/schedule/:application_id`) currently requires an examiner to have an `AvailabilityRule` to show slots. If none exists, it renders `No team members have set their availability yet → Set Availability` with no ad-hoc fallback. Fresh tenants (e.g. `Friction Co 86`) hit this before any value, blocking `New → Interview`. The `Pipeline` board shows `Interview not scheduled` blockers but no `Schedule` CTA that works in zero-state.

## Goals / Non-Goals

**Goals:**
- Allow scheduling an interview when no availability rules exist, via ad-hoc datetime + examiner picker.
- Keep availability-aware slot computation when rules exist.
- Surface a `Schedule interview` CTA on the pipeline Interview card even in zero-state.

**Non-Goals:**
- No calendar provider change, no Oban.
- No auto-creation of availability rules (deferred).

## Decisions

**Decision 1 — Ad-hoc fallback form (chosen).**
- When `eligible_examiners == []` or `list_eligible_examiners` empty, render datetime pickers + examiner multi-select + `Schedule anyway` that calls `Interviews.schedule_interview` directly with the chosen time, bypassing `compute_overlapping_slots`.
- Why: Unblocks first interview; preserves existing path when rules exist.

**Decision 2 — Pipeline CTA.**
- Add `Schedule interview` button on Interview stage cards that links to `/app/schedule/:application_id` regardless of `interview_not_scheduled` blocker.

## Risks / Trade-offs

- **[Risk] Double-booking when no availability check** → Mitigation: show warning `No availability set — double-booking not checked`.
- **[Risk] Timezone confusion** → Mitigation: use tenant's default timezone (UTC) and display `UTC` suffix.

## Migration Plan

- No migration.

## Open Questions

- None.
