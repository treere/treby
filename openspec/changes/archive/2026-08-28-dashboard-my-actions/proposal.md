## Why

The hiring flow stalls at the interview stage because progress depends on individual team members completing their part (submitting scorecards, marking interviews completed, advancing candidates). The system already computes exactly who must do what (`current_state/1`, `scorecard_completion_status/1`, `list_upcoming_for_user/1`), but this is only shown scattered across per-candidate pipeline cards. Each team member must scan the whole board to discover their own outstanding work. We want to remove that friction by surfacing each user's own pending actions directly to them — pure facilitation of the existing manual flow, with no automation or AI.

## What Changes

- Add a "My Actions" panel to the dashboard that aggregates the current user's actionable items, grouped by action type.
- Each action shows the candidate, job, interview context, and a direct "click-to-do" control that reuses existing handlers (`open_scorecard`, `complete_interview`, `advance_application`).
- Actions are strictly filtered by the same role rules already used in the pipeline UI, so a user only ever sees actions they are authorized to perform.
- Only the highest-impact, least ambiguous action type is included in the first iteration: **pending scorecards** (the user is an examiner on an interview where their scorecard is missing). This is the #1 bottleneck of the flow.
- A "waiting on others" secondary display is included (read-only, no action) so the user understands why things are blocked, reusing `current_state` blockers.
- No automation, no AI, no automatic notifications introduced.

## Capabilities

### New Capabilities
- `dashboard-my-actions`: Aggregates and displays the current user's pending hiring actions (initially pending scorecards, plus a read-only "waiting on others" view) on the dashboard, filtered by the user's role permissions, with direct actions reusing existing handlers.

### Modified Capabilities
- `dashboard`: Adds the "My Actions" panel to the dashboard alongside the existing upcoming-interviews, stale-candidates, pipeline-snapshot, and weekly-stats panels.

## Impact

- **Code**: `Treby.Dashboard` (new data aggregation), `TrebyWeb.DashboardLive` (new panel + handlers), templates in `dashboard_live.ex`. Reuses `Treby.Pipeline.current_state/1`, `Treby.Interviews.scorecard_completion_status/1`, and existing event handlers — no domain-model changes.
- **Specs**: New `specs/dashboard-my-actions/spec.md`; delta `specs/dashboard/spec.md`.
- **No** database schema changes, no new dependencies, no API changes.
