## Why

Fresh tenants have no `AvailabilityRule`s, so `GET /app/schedule/:application_id` shows only `No team members have set their availability yet.` No ad-hoc fallback. First interview requires `Settings → Availability` pre-config + `examiner`/`advancer` assignment, which is undiscoverable. This was the top friction before crashes.

## What Changes

- When no rules exist, show an ad-hoc time picker (date + time + duration + examiner select) alongside the empty-state message, allowing one-off scheduling without creating recurring rules.
- Keep existing slot calculation when rules exist; ad-hoc path creates a single `InterviewEvent` with `tenant_id`/`end_at_utc` computed.
- Surface a helper link `Set weekly availability → Settings → Availability` but do not block.

## Capabilities

### New Capabilities
- `interview-scheduling-zero-state`: Ad-hoc scheduling when no availability.

### Modified Capabilities
- `interview-scheduling`: Zero-state now offers direct scheduling.

## Impact

- `lib/treby_web/live/schedule_live/index.ex` — empty-state branch.
- `lib/treby/interviews` — `schedule_interview` with `tenant_id`/`end_at_utc` handling (already required).
- `lib/treby/availability` — no schema change.
- Docs: `site/features/scheduling.md` (if exists) copy update, screenshots via `node scripts/screenshots.mjs`.
