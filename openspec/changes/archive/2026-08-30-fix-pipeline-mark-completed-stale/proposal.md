## Why

After `Mark as completed` for an interview, the pipeline card still shows `Interview not yet completed` + `scorecard missing` until `location.reload()`. `InterviewEvent` is `completed` in DB and `Pipeline.current_state(blocked?: false)` but LiveView does not re-render the card. This stale UI confused the retest (`Frank Dome`).

## What Changes

- After `mark_completed`, broadcast `pipeline:#{job.id}` and re-stream the affected application (or reload `assign(:applications)`), so `current_state` is recomputed and `Scorecard`/`Advance` states update without manual reload.
- Cover both `handle_event "mark_completed"` and `handle_info` PubSub path.
- Add PubSub test: `mark_completed` → card shows `Ready to advance` / `UX Tester: scorecard missing` only (not `Interview not yet completed`).

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `pipeline`: Interview completion reflects live without reload.

## Impact

- `lib/treby_web/live/pipeline_live/index.ex` — `handle_event` + `handle_info`.
- `lib/treby/interviews` — no change, just trigger.
- No DB migration.
