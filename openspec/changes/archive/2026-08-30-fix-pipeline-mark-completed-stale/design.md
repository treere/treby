## Context

After `Mark as completed` for an interview in `PipelineLive.Index`, the card still shows `Interview not yet completed` + `scorecard missing` until manual reload. `InterviewEvent.status == "completed"` in DB and `Pipeline.current_state(blocked?: false)` but LiveView does not re-render blockers. Local handler reloads `applications_by_stage` but does not broadcast, so other tabs/clients stay stale. Retest with Frank Dome reproduced.

## Goals / Non-Goals

**Goals:** Marking interview completed immediately updates card to `Ready to advance` / `scorecard missing` without reload; other pipeline sessions receive `pipeline:#{job_id}` update.

**Non-Goals:** Changing interview business rules; adding new UI.

## Decisions

- Broadcast `{:pipeline_updated, job_id}` from `Treby.Interviews.complete_interview/2` on topic `pipeline:#{job_id}` (same as `Pipeline.move_application`). This covers all entry points (pipeline board, candidate show, interviews list).
- Keep existing `PipelineLive.Index.handle_info {:pipeline_updated}` which already reloads `applications_by_stage`, `application_counts`, `upcoming_interviews` so no change needed there. Keep local reload in `handle_event "confirm_complete_interview"` for immediate feedback.
- No migration.

## Risks / Trade-offs

- [Risk] Double reload (local + broadcast to self) → Mitigation: idempotent reload, cheap.
