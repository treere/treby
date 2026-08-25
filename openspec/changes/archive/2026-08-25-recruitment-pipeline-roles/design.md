# Design: Recruitment Pipeline Roles

## Context

Treby is a Phoenix-based ATS with pipeline management, interview scheduling, scorecards, and Google Calendar integration. The current model supports single-interviewer events with no role differentiation per stage. This change introduces:

- Pipeline templates for reusable configurations
- Per-stage role assignments (examiner, reviewer, advancer)
- Multi-examiner interview events with overlapping availability
- Advancement gated by scorecard completion

The codebase uses Ecto with PostgreSQL, UUID primary keys, and LiveView for the UI.

## Goals / Non-Goals

**Goals:**
- Allow teams to define stage-level roles (examiner, reviewer, advancer) per pipeline
- Support multi-examiner interview events where all examiners attend the same call
- Compute overlapping availability across examiners for scheduling
- Gate advancement from interview stages on scorecard completion
- Enable template-based pipeline creation for similar positions

**Non-Goals:**
- Changing the existing admin/member role system (stage roles are an additional layer)
- Supporting sequential interview rounds within a single stage (that's multiple stages)
- Auto-advancing candidates based on scorecard results (advancement remains manual)
- Weighted scoring or consensus algorithms for multi-examiner scorecards

## Decisions

### D1: Pipeline templates as `is_template` flag on `pipelines`

**Decision:** Add a boolean `is_template` field to the existing `pipelines` table rather than creating a separate `pipeline_templates` table.

**Rationale:** Templates have the same structure as pipelines (stages, role assignments). A separate table would duplicate the schema and context functions. The `is_template` flag cleanly separates templates from active pipelines while sharing the same data model.

**Alternatives considered:**
- Separate `pipeline_templates` table — rejected: duplications of PipelineStage management code, divergent schemas over time
- Polymorphic `type` field — rejected: overengineered for two types

### D2: Role assignments as junction tables

**Decision:** Create three junction tables: `pipeline_stage_examiners`, `pipeline_stage_reviewers`, `pipeline_stage_advancers`.

**Rationale:** Many-to-many relationships between stages and users require junction tables. Separate tables per role (vs. a single `pipeline_stage_roles` with a `role` column) provide:
- Clear schema introspection
- Simpler queries (no role column filtering)
- Independent foreign key constraints
- Easier migration if roles gain additional attributes

**Schema:**
```
pipeline_stage_examiners
  pipeline_stage_id :binary_id (FK → pipeline_stages)
  user_id           :binary_id (FK → users)
  inserted_at       :utc_datetime

pipeline_stage_reviewers
  pipeline_stage_id :binary_id (FK → pipeline_stages)
  user_id           :binary_id (FK → users)
  inserted_at       :utc_datetime

pipeline_stage_advancers
  pipeline_stage_id :binary_id (FK → pipeline_stages)
  user_id           :binary_id (FK → users)
  inserted_at       :utc_datetime
```

### D3: Multi-examiner events via junction table

**Decision:** Create `interview_event_examiners` junction table instead of multiple `interview_event` records per slot.

**Rationale:** One event with multiple examiners is semantically correct — it's one meeting with multiple participants. Multiple event records would fragment the event lifecycle (one cancel cancels all, one reschedule reschedules all).

**Schema:**
```
interview_event_examiners
  interview_event_id :binary_id (FK → interview_events)
  user_id            :binary_id (FK → users)
  status             :string (default "scheduled") — scheduled/cancelled
  inserted_at        :utc_datetime
```

**Breaking change:** Remove `interviewer_id` from `interview_events`. All references to "the interviewer" of an event now go through `interview_event_examiners`.

### D4: Overlapping availability algorithm

**Decision:** Compute availability by intersecting free/busy data across all eligible examiners, then filter for slots where ≥ `min_examiners` are free.

**Algorithm:**
```
function compute_overlapping_slots(examiners, min_examiners, date_range, duration):
  for each day in date_range:
    // Get availability rules intersection
    avail_windows = intersect_availability_rules(examiners, day)

    for each window in avail_windows:
      // Get busy periods from Google Calendar for each examiner
      busy_periods = for each examiner:
        GoogleCalendar.freeBusy(examiner, window.start, window.end)

      // Find free slots per examiner
      free_slots = for each examiner:
        subtract_busy(window, busy_periods[examiner])

      // Intersect free slots across examiners
      // Keep slots where count(free examiners) >= min_examiners
      overlapping = intersect_with_count(free_slots, min_examiners, duration)

  return overlapping
```

**Performance consideration:** This requires N+1 Google Calendar API calls (1 per examiner per date range). Mitigation:
- Batch free/busy queries using Google Calendar `freeBusy` API with multiple items
- Cache results for 5 minutes per examiner per date range
- Run computation async and push results via PubSub

### D5: Scorecard template per stage (not per pipeline)

**Decision:** Associate scorecard templates with individual pipeline stages, not the pipeline as a whole.

**Rationale:** Different interview stages evaluate different things (technical vs cultural). Each stage should have its own evaluation criteria.

**Implementation:** Add `scorecard_template_id` FK to `pipeline_stages`. When template is cloned, the association is copied.

### D6: Booking tokens link to stage, not interviewer

**Decision:** For multi-examiner stages, booking tokens reference `pipeline_stage_id` instead of `interviewer_id`.

**Rationale:** The candidate doesn't choose an interviewer — they choose a time slot. The system assigns examiners based on availability. The booking token must know which stage's examiner pool to use.

**Migration:** Make `interviewer_id` on `booking_tokens` nullable. Add `pipeline_stage_id` nullable FK. Backfill existing tokens.

### D7: Examiner substitution is manual-assisted

**Decision:** When an examiner cancels, the system suggests substitutes but requires human confirmation for the replacement.

**Rationale:** Automated substitution could assign someone who has context constraints not captured in calendar data (e.g., conflict of interest, role restrictions). The system finds candidates, the advancer decides.

**Flow:**
1. Examiner cancels → event status stays "scheduled"
2. System finds eligible examiners with overlapping availability
3. Advancer receives notification with substitute options
4. Advancer confirms substitute → examiner swapped, new calendar event created
5. If no substitute found → advancer can reschedule or cancel

### D8: Advancement gating for interview stages

**Decision:** For stages of type "interview", the advancement action is disabled until all examiners have submitted scorecards. This is a UI-level gate, not a database constraint.

**Rationale:** A database constraint would prevent edge cases like manual stage moves via IEx or admin tools. The UI gate provides the user experience while the backend `move_application` function remains permissive for emergency overrides.

**Implementation:**
- Add `all_scorecards_completed?(application_id)` function to `Pipeline` context
- Check in LiveView before rendering the "Advance" button
- Add a guard in `handle_event("advance", ...)` that returns an error if scorecards are incomplete

## Risks / Trade-offs

**[Risk] Calendar API rate limits with many examiners** → Batch freeBusy queries, cache aggressively, compute asynchronously. Worst case: degrade gracefully by showing "checking availability..." spinner.

**[Risk] Breaking change: interviewer_id removal from interview_events** → Write a migration that backfills `interview_event_examiners` from existing `interviewer_id` values before dropping the column.

**[Risk] Complexity of overlapping availability computation** → Start with a simple implementation (check each slot, count available examiners). Optimize later if performance is an issue. The date range is bounded (14 days) and examiner count per stage is small (2-5 typical).

**[Trade-off] Separate junction tables vs single roles table** → More tables but cleaner queries and schema. Acceptable given the small number of roles (3).

## Migration Plan

1. **Phase 1 — Schema additions (no breaking changes)**
   - Add `is_template` to `pipelines`
   - Add `min_examiners` to `pipeline_stages`
   - Add `scorecard_template_id` to `pipeline_stages`
   - Create junction tables: `pipeline_stage_examiners`, `pipeline_stage_reviewers`, `pipeline_stage_advancers`, `interview_event_examiners`
   - Add `pipeline_stage_id` to `booking_tokens`

2. **Phase 2 — Data migration**
   - Backfill `interview_event_examiners` from existing `interviewer_id` on `interview_events`
   - Backfill `booking_tokens` with `pipeline_stage_id` from linked application's stage

3. **Phase 3 — Breaking changes**
   - Remove `interviewer_id` from `interview_events`
   - Make `interviewer_id` on `booking_tokens` nullable (keep for backward compat during transition)

4. **Phase 4 — Feature rollout**
   - Template management UI
   - Stage role assignment UI
   - Multi-examiner scheduling engine
   - Self-scheduling with overlapping availability
   - Advancement gating
   - Scorecard completion tracking

## Open Questions

- Should `min_examiners` be enforced at the database level (CHECK constraint) or only in application logic?
- What happens if an examiner is removed from a stage while they have a pending scorecard for an event in that stage?
- Should the "interviews dashboard" show each examiner as a separate row, or group by event?
