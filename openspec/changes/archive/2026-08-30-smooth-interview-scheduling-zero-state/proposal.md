## Why

Scheduling the first interview is impossible until an examiner has created an `AvailabilityRule`. Live testing at `/app/schedule/:application_id` (Backend Engineer → Alice Dome) showed the `Select Interviewer` panel rendering only `No team members have set their availability yet → Set Availability`, with no way to pick a time ad-hoc. This is a hard precondition hidden in `Settings → Availability` (`availability_rules` table) that blocks the core flow `New → Interview` on a fresh tenant. Recruiters expect to schedule immediately (pick a date/time, invite examiners) without pre-configuring weekly hours.

## What Changes

- Allow interview scheduling without pre-existing availability (zero-state smooth path):
  - On `Schedule Interview` (`TrebyWeb.ScheduleLive.Index`): when `eligible_examiners == []` or no availability rules exist, render an `Ad-hoc scheduling` fallback: datetime pickers + examiner multi-select + `Schedule anyway` CTA, with a helper `Tip: set recurring availability in Settings → Availability to enable automatic slot finding`.
  - Keep the existing availability-aware path (`compute_overlapping_slots`, `list_eligible_examiners`) when rules exist; do not regress the slot-computation UI.
  - On `Pipeline → Interview` stage cards: surface a `Schedule interview` button that deep-links to `/app/schedule/:application_id` even in zero-state, instead of showing only blockers (`interview_not_scheduled`) with no action.
  - Optional: auto-create a minimal availability rule for the scheduling user if they confirm ad-hoc time (deferred to design).
- Preserve calendar provider flow (Google/Jitsi) and `InterviewEvent` creation (`Treby.Interviews.schedule_interview`) — only relax the examiner-availability gate.

## Capabilities

### New Capabilities
- `interview-scheduling-zero-state`: Ad-hoc interview scheduling when no availability rules exist, ensuring the first interview can be created on a fresh tenant without visiting Settings.

### Modified Capabilities
- `interview-scheduling`: Extend scheduling requirements to include a zero-state fallback; the page SHALL render a usable scheduling form even when no team member has availability.
- `availability-rules`: Clarify that availability is an optimization for slot finding, not a hard gate for scheduling.

## Impact

- Affected code: `lib/treby_web/live/schedule_live/index.ex`, `lib/treby/availability/availability.ex`, `lib/treby/pipeline/pipeline.ex` (`list_eligible_examiners`, `current_state` blockers), `lib/treby/interviews/interviews.ex`
- No schema migration — reuses `availability_rules`, `interview_events`, `event_examiners`.
- Docs: update `site/features/interviews.md` to mention ad-hoc vs availability-based scheduling.
- Tests: extend `test/treby_web/live/schedule_live_test.exs` and `test/treby_web/integration/scheduling_live_test.exs` to cover zero-state path.
