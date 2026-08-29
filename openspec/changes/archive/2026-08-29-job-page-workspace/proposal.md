## Why

The job detail page is a read-only dead end. Candidates are listed flat with no actions: you can't change their stage, mark them reviewed, reject them, or open their profile — and when you do open a profile, the back link always returns to the full candidate list, losing the job context. The pipeline editor is always expanded and always editable, pushing admin configuration into the daily view. As a result, everyday work (checking who is in which stage, moving candidates forward, reviewing applications, opening profiles) forces users to leave the job page for the Kanban board or candidate pages, losing context at every hop.

## What Changes

- **Job detail page becomes a self-contained daily workspace**: candidates are grouped by pipeline stage (columns) with per-stage counts, so the state of the position is visible at a glance.
- **Each candidate card on the job page** gains the interactions currently locked in the Kanban:
  - Links to the candidate profile
  - Inline stage-change dropdown ("Move to…")
  - Review toggle (NEW badge)
  - Reject action with the existing rejection flow
  - Badges: DUPLICATE, "Also in N other positions"
  - Upcoming interview indicator and resume link
- **Search/filter** within the job's candidates.
- **Pipeline section becomes a read-only overview** by default (stages in order, colors, candidate counts, and the names of assigned examiners/reviewers/advancers), with a **"Manage Pipeline" CTA** that reveals the editor. Editing stays admin-only.
- **Contextual back navigation**: the candidate profile returns to the originating page (job, Kanban, interviews) instead of always the candidate list.
- **Kanban board remains** for heavy/advanced operations (drag & drop, bulk actions, scheduling, scorecards, real-time collaboration) but its entry from the job page becomes less prominent.

## Capabilities

### New Capabilities
- `job-page-candidate-management`: candidates grouped by stage on the job detail page, inline stage moves, review toggle, reject, contextual badges, search/filter, and profile links.
- `contextual-candidate-navigation`: the candidate profile's back link honors a validated return origin instead of always pointing to the candidate list.

### Modified Capabilities
- `job-pipeline-editor`: pipeline shown read-only by default with role names in the overview; editing behind a "Manage Pipeline" CTA.
- `application-review`: review indicator and toggle available on job-page candidate cards, not only on the Kanban board.
- `pipeline`: Kanban retained as the dedicated page for advanced operations; entry point from the job page de-emphasized.

## Impact

- `lib/treby_web/live/jobs_live/show.ex` — rework of the candidates and pipeline sections (the largest change).
- `lib/treby_web/live/candidates_live/show.ex` — back navigation honoring `return_to`.
- `lib/treby_web/live/pipeline_live/index.ex` — de-emphasized entry link; behavior otherwise unchanged.
- Reuses existing context functions: `Pipeline.move_application/3` (stage moves, activity log, PubSub, notifications), `mark_reviewed`/`mark_unreviewed`, the rejection flow, and `refresh_roles` for role names.
- Real-time: the job page subscribes to `pipeline:#{job_id}` for consistent multi-user state.
- Tests: `jobs_live_show_test.exs`, `candidates_live_show_test.exs`, `application-review` and pipeline tests; new coverage for stage moves and return navigation.
- Docs/site: `site/features/pipeline.md` and `site/features/candidate-management.md` updated, screenshots regenerated via `node scripts/screenshots.mjs`.