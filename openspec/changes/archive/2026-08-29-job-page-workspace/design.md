## Context

`JobsLive.Show` (`/app/jobs/:id`) is currently a read-only detail page: a flat candidate list (name, email, stage badge, date) with no actions, and a permanently-expanded, always-editable pipeline editor for admins. All daily operations live in `PipelineLive.Index` (the Kanban board) or `CandidatesLive.Show` (whose back link always points to `/app/candidates`, losing context).

The data and context functions needed already exist:
- `Pipeline.list_applications_by_stage/1` returns `[{stage, [applications]}]` in stage order, candidates preloaded.
- `Pipeline.move_application/3` performs stage moves with activity logging, PubSub broadcast, and notification email (honors `:skip_notification`).
- `Pipeline.mark_reviewed/1`, `mark_unreviewed/1`, `toggle_reviewed/1` manage review state.
- `Pipeline.candidate_application_counts/2` and `other_positions_text/2` provide the "Also in N other positions" indicator.
- `Pipeline.current_state/1`, `user_is_advancer?/2`, `ready_to_advance?/1` gate stage interactions.
- `JobsLive.Show` already loads `stages_with_counts/1` and `refresh_roles/1` (examiner/reviewer/advancer names).

No schema changes are required; this is a UI/UX rework of existing views reusing existing context functions.

## Goals / Non-Goals

**Goals:**
- Make `/app/jobs/:id` self-sufficient for daily recruiting work for that position.
- Reuse existing context functions and permission gating so behavior stays consistent with the Kanban.
- Keep the Kanban board intact for heavy/advanced operations.

**Non-Goals:**
- Removing or merging the Kanban board into the job page (evaluated after this change lands).
- Adding drag-and-drop to the job page.
- Changing the pipeline editing capabilities themselves (only their presentation).
- Changing candidate-profile content beyond its back navigation.

## Decisions

### D1. Candidates grouped by pipeline stage in columns
Use `Pipeline.list_applications_by_stage(job_id)` as the source of truth for the candidates section. Render one column per stage (in position order) with a count header, and reuse the Kanban card's visual language (name, email, NEW/DUPLICATE badges, "Also in N other positions", upcoming interview chip, resume link).

**Alternatives considered:** flat list with a stage filter (loses the at-a-glance view), an accordion of expandable stages (more clicks). Chose columns because they satisfy the "who is where" question at a glance — the primary daily interaction.

### D2. Inline stage change via per-card dropdown
Each card shows a "Move to…" select listing the job's effective pipeline stages, preselected to the current stage. On change it fires `move_application` → `Pipeline.move_application/3` (actor passed) → grouped apps refreshed from the broadcast.

**Alternatives considered:** advance-only button (fast but non-obvious destination and no backwards moves), left/right arrows (only adjacent moves). Chose the dropdown for explicitness and full flexibility; it reuses the exact side-effect path (activity log, PubSub, notification email) already used by the Kanban.

**Permission gating:** mirror the Kanban — moving into/out of an interview stage requires the user to be an advancer (`Pipeline.user_is_advancer?/2`); the select is disabled otherwise. The dropdown is disabled when the effective pipeline has a single stage.

### D3. Real-time consistency on the job page
Subscribe the job page to `pipeline:#{job_id}` (`Pipeline.subscribe_to_pipeline/1`) and handle `{:pipeline_updated, job_id}` by reloading grouped apps, counts, and upcoming interviews. This keeps two recruiters working the same job in sync and matches the Kanban's behavior.

### D4. Review toggle, reject, and badges on the job page
- **Review toggle:** per-card click calling `Pipeline.toggle_reviewed/1`, then refresh. The NEW badge derives from `reviewed == false`.
- **Reject:** replicate the Kanban's rejection modal pattern in `JobsLive.Show` (`rejecting_application` assign, reason input, `confirm_reject` handler) reusing the same logic: resolve the `stage_type == "rejected"` stage, `move_application/3` with `attrs: %{rejection_reason: reason}`, create the rejection conversation and ping email. Reuse `Pipeline.user_is_advancer?` to gate the button.
- **Badges:** DUPLICATE from `is_duplicate`, "Also in N other positions" from `Pipeline.candidate_application_counts/2`, upcoming interview from the same scheduled-interview query the Kanban uses.

**Alternative considered:** linking out to the Kanban for these actions. Chose inline actions because the goal is to avoid context hops.

### D5. Pipeline read-only overview with a "Manage Pipeline" CTA
By default the pipeline section renders a read-only overview: stages in order with color dot, name, type, candidate count per stage, and the **names** of assigned examiners/reviewers/advancers (from `refresh_roles/1`-style loading). A "Manage Pipeline" button (admin-only) toggles a `manage_pipeline` assign that reveals the existing editor (add/edit/reorder/delete/roles) unchanged.

**Alternatives considered:** moving the editor into a modal. Chose inline expansion because the existing handlers and tests operate on the current markup; expansion is a smaller, safer change.

### D6. Contextual back navigation via `return_to` query param
Entry points to the candidate profile add `?return_to=/app/jobs/:id` (job page cards) and similarly for Kanban/interviews/schedule. `CandidatesLive.Show` reads `params["return_to"]`, validates it against an internal-path whitelist (`/app/*` prefixes), and renders "← Back to {label}" where the label is derived from the known path prefixes (job, pipeline, candidates). Invalid or missing values fall back to the existing "← Back to Candidates".

**Alternatives considered:** storing the last location in the LiveView process/session. Chose the query param because it survives refresh and deep links, is stateless, and is trivially validated.

### D7. Kanban de-emphasis
The job page's pipeline entry button changes from the primary blue button to a secondary/outline style, keeping the Kanban reachable for drag-and-drop, bulk actions, scheduling, and scorecards. No Kanban behavior changes.

**Optional polish (phase 5):** per-job candidate counts on the jobs index page, and an updated "View Pipeline" label (e.g. "Bulk & Scheduling") — both deferred until the workspace lands.

## Risks / Trade-offs

- **Page complexity grows** → Keep columns compact, reuse the Kanban card markup via a shared function component (e.g. in `TrebyWeb.CoreComponents` or a shared partial) so the two views stay visually and behaviorally consistent.
- **Role/permission divergence** between job page and Kanban → Reuse the same `Pipeline` permission helpers (`user_is_advancer?`, `current_state`, `ready_to_advance?`) so gating is identical.
- **Quick stage moves send notification emails** (existing `move_application/3` behavior) → Accepted for consistency with the Kanban; a `:skip_notification` opt-in for triage can be added later if noisy.
- **Open redirect via `return_to`** → Mitigated by a strict internal `/app/*` whitelist; invalid values fall back to the candidate list.
- **Race with real-time updates** → Mitigated by D3 (subscribe + refresh on broadcast), which also makes the Kanban reflect job-page moves immediately.

## Migration Plan

- Purely additive UI rework; no schema or data migration.
- Deploy in phases matching the task list (return_to → pipeline read-only → candidates by stage → per-card actions → polish) so each is independently testable.
- Rollback: revert the UI changes; no data written by the rollout itself (all writes already use existing production code paths).

## Open Questions

- Whether the shared candidate-card markup is extracted as a function component now or kept duplicated during the initial implementation (preference: extract, but it can be deferred).
- Final label and placement of the de-emphasized Kanban entry button ("View Pipeline" ghost button vs. relabeled "Bulk & Scheduling").
- Whether per-job counts on the jobs index (optional polish) should ship in this change or as a follow-up.