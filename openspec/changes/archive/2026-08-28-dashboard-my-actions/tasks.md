## 1. Dashboard aggregation

- [x] 1.1 Add `Treby.Dashboard.my_actions/2` (or extend `get_dashboard_data/2`) that computes the current user's pending scorecards: interview events where the user is an examiner and their scorecard is missing, with candidate, job, and interview-date context (reuse `Treby.Interviews.scorecard_completion_status/1` semantics, batched to avoid N+1).
- [x] 1.2 Add a read-only "waiting on others" list derived from `Treby.Pipeline.current_state/1` blockers: applications at an interview stage blocked by other examiners' missing scorecards or an incomplete interview, with the pending names/status.
- [x] 1.3 Add unit tests for the new aggregation (pending scorecards for the user, exclusion of others' missing scorecards, empty state, waiting-on-others contents).

## 2. Dashboard LiveView panel

- [x] 2.1 Extend `TrebyWeb.DashboardLive.mount/3` to load the my-actions data from `Treby.Dashboard` and assign it to the socket.
- [x] 2.2 Add a "My Actions" panel in `dashboard_live.ex` below the weekly stats: a pending-scorecards list with candidate, job, interview date, and a "Fill scorecard" action, plus an empty state when there is nothing pending.
- [x] 2.3 Add the read-only "waiting on others" section within the panel (no action controls).
- [x] 2.4 Add the `open_scorecard` → `submit_scorecard` handler flow to the dashboard (reusing the existing scorecard form logic from pipeline/candidates), including `close_scorecard` and refreshing the panel after submit.
- [x] 2.5 Add LiveView tests: panel renders with pending scorecards, empty state when none, "Fill scorecard" opens the form, submitting records the scorecard and removes the item, waiting-on-others section renders read-only.

## 3. Docs & polish

- [x] 3.1 Update the dashboard feature page in `site/features/` to describe the My Actions panel.
- [x] 3.2 Regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 3.3 Run `mix precommit` and resolve any lint/format/credo issues.
