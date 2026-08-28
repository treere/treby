## Context

The hiring flow stalls at interview stages because advancement depends on every assigned examiner submitting a scorecard (`ready_to_advance?` requires interview completed AND all scorecards submitted). The system already knows exactly who must do what:

- `Treby.Pipeline.current_state/1` returns `blockers` (with `assignee` names) and `next_actions` per application.
- `Treby.Interviews.scorecard_completion_status/1` returns `completed`/`total`/`pending` per interview event.
- `Treby.Dashboard.get_dashboard_data/2` already aggregates dashboard data (upcoming interviews, stale candidates, pipeline snapshot, weekly stats) for `TrebyWeb.DashboardLive`.

Today this "who must do what" knowledge is only surfaced per-candidate on pipeline cards. Each team member must scan the whole board to discover their own outstanding work. The dashboard is the natural home: it already exists as the user's daily attention center and already has an "Upcoming Interviews" panel.

This change is **pure facilitation of the existing manual flow** — no automation, no AI, no new decision-making.

## Goals / Non-Goals

**Goals:**
- Give each team member a single, actionable view of *their* outstanding work.
- Reduce the interview-stage bottleneck by surfacing the most impactful, least ambiguous action: **pending scorecards** (user is examiner, their scorecard is missing).
- Reuse existing domain logic and event handlers; add no new domain concepts.
- Strictly respect existing role permissions so a user only sees actions they can perform.

**Non-Goals:**
- No automation, AI, or automatic notifications/suggestions.
- No new action types beyond pending scorecards in this iteration (advance/complete-interview are explicitly deferred).
- No changes to the pipeline board, candidate portal, or scorecard forms themselves.
- No database schema changes or new dependencies.

## Decisions

### Decision 1: Place the panel in the existing dashboard
Add a "My Actions" panel to `TrebyWeb.DashboardLive` rather than creating a new route/page.

**Why:** The dashboard is already the daily attention center; the panel is coherent with its existing panels. No new navigation path or permission surface. **Alternative considered:** a dedicated route — rejected as heavier and disconnected from where users already look.

### Decision 2: New aggregation in `Treby.Dashboard`
Add `my_actions(tenant_id, user_id)` (or extend `get_dashboard_data/2`) that returns pending actions for the user.

**Why:** Keeps query logic in the Dashboard context, consistent with existing `upcoming_interviews/3`, `stale_candidates/2`, etc. **Alternative considered:** computing in the LiveView — rejected to keep LiveViews thin and the aggregation testable in the context.

### Decision 3: First iteration = pending scorecards only
The panel's actionable list shows, for the current user, interviews where they are an examiner and their scorecard is missing. Computed via `scorecard_completion_status/1` (pending contains the user) over the user's scheduled/upcoming interviews.

**Why:** It is the #1 bottleneck and the most unambiguous action ("you are the examiner, your scorecard is missing — fill it"). Advance/complete-interview involve more role nuance (`user_is_advancer?`, `can_complete?`) and are deferred to a later iteration. **Alternative considered:** including all action types at once — rejected to keep the first version small and validated.

### Decision 4: Reuse existing handlers for the action
Each pending-scorecard row's "Fill scorecard" control reuses the existing `open_scorecard` → `submit_scorecard` flow (currently used in pipeline and candidates show). The row links to the candidate/application context.

**Why:** No new form/domain logic; the scorecard modal already exists and is battle-tested. **Alternative considered:** a new dedicated scorecard page — rejected as duplication.

### Decision 5: Secondary read-only "waiting on others"
The panel also shows a read-only list of applications where the user's progress is blocked by others, derived from `current_state/1` blockers (e.g., "Waiting on 2 scorecards from [names]", "Interview not yet completed").

**Why:** It explains *why* things are blocked without inventing new decisions — it just surfaces existing state. It gives the user (especially advancers/coordinators) the context to nudge or follow up. No action controls here. **Alternative considered:** omitting it entirely — rejected because it removes the "why blocked" clarity that reduces confusion; but kept strictly read-only to honor the non-goal of no automation.

### Decision 6: Role filtering reuses existing predicates
Actions are filtered by the same rules already in the pipeline UI. For pending scorecards, the filter is simply "user is an examiner on the event and their scorecard is missing" (exactly `scorecard_completion_status/1` pending semantics). No new authorization code is added for this iteration.

**Why:** Guarantees the user never sees an action they cannot perform. **Alternative considered:** new permission helper — rejected as unnecessary for the scorecard case.

## Risks / Trade-offs

- **[Only scorecards, limited scope]** The panel won't surface "advance" or "complete interview" yet, so some actions remain discoverable only on the board. → Mitigation: explicitly scoped as first iteration; the "waiting on others" read-only view still surfaces blockers, and the panel can grow in later changes.
- **[Performance]** Aggregating scorecard status across many upcoming interviews could add N+1 queries to the dashboard. → Mitigation: batch query scorecards for the relevant event ids (mirroring `scorecard_completion_status/1`'s approach) and preload examiners/users; reuse the existing single `get_dashboard_data/2` call.
- **[Feature creep toward automation]** The read-only "waiting on others" view could be tempted to add auto-nudges. → Mitigation: keep it strictly read-only and state the non-goal explicitly in code comments and spec.

## Migration Plan

- This is additive: `Treby.Dashboard` gains a function, `TrebyWeb.DashboardLive` gains a panel. No schema change, no data migration, no breaking change.
- Rollback: remove the panel and the new function; existing behavior is untouched.
- After implementation, update the feature documentation in `site/` and regenerate screenshots per the project guidelines.

## Open Questions

- Should the "waiting on others" section be shown to everyone, or only coordinators/advancers? (Default: shown to everyone, read-only.)
- Panel placement within the dashboard (top vs. below weekly stats)? Default: below weekly stats, above the two-column grid — to be confirmed at implementation time with the existing layout.
