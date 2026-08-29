## 1. Contextual back navigation (return_to)

- [x] 1.1 Add `return_to` query-param support to `CandidatesLive.Show.mount/3`: read `params["return_to"]`, validate against an internal `/app/*` whitelist, and store a `return_path` assign (fallback: `/app/candidates`)
- [x] 1.2 Derive a back-link label from the return path (job page, pipeline board, candidates list) and render "← Back to {label}" in the candidate profile header, keeping the existing "Back to Candidates" as the fallback
- [x] 1.3 Add `return_to` to the candidate-name links on the job page candidate cards and on the Kanban board cards
- [x] 1.4 Test: candidate profile back link returns to the originating job; falls back to candidates list for direct/invalid return paths

## 2. Pipeline read-only overview + Manage Pipeline CTA

- [x] 2.1 Add a `manage_pipeline` boolean assign to `JobsLive.Show` (default false) and a "Manage Pipeline" button (admin-only) that toggles it
- [x] 2.2 Replace the default pipeline editor markup with a read-only overview: stages in position order showing color, name, type, candidate count per stage, and the names of assigned examiners/reviewers/advancers (reuse `refresh_roles/1`-style loading)
- [x] 2.3 Keep the existing editor markup (add/edit/reorder/delete/roles) rendered only when `manage_pipeline` is true
- [x] 2.4 Test: non-admin and admin see the read-only overview by default; admin sees editing controls only after clicking "Manage Pipeline"

## 3. Candidates grouped by stage + inline moves + real-time

- [x] 3.1 Switch `JobsLive.Show` to load grouped candidates via `Pipeline.list_applications_by_stage/1`; render one column per stage with a count header and an empty state per empty column
- [x] 3.2 Reuse the Kanban card visual language (name, email, NEW/DUPLICATE badges, other-positions indicator, upcoming-interview chip, resume link) in the job-page cards; make the candidate name a link to the profile with `return_to`
- [x] 3.3 Add a per-card "Move to…" stage selector listing the job's effective pipeline stages, and a `move_application` event calling `Pipeline.move_application/3` (actor passed); refresh grouped cards on success
- [x] 3.4 Enforce permission gating on the selector: disable for non-advancers on interview stages and when the pipeline has a single stage (reuse `Pipeline.user_is_advancer?/2`)
- [x] 3.5 Subscribe the job page to `pipeline:#{job_id}` and handle `{:pipeline_updated, job_id}` by reloading grouped cards, counts, and upcoming interviews (real-time consistency with the Kanban)
- [x] 3.6 Test: cards grouped per stage with counts; moving a candidate updates the columns and broadcasts to the Kanban; selector disabled for non-advancers and single-stage pipelines

## 4. Per-card actions on the job page

- [x] 4.1 Add a per-card review toggle calling `Pipeline.toggle_reviewed/1` and refresh the grouped cards (NEW badge reacts)
- [x] 4.2 Add the rejection flow to `JobsLive.Show`: `rejecting_application` assign, reason input, and a `confirm_reject` handler replicating the Kanban logic (resolve rejected stage, `move_application/3` with `rejection_reason`, create rejection conversation + ping email); gate the button to advancers
- [x] 4.3 Add a search input in the candidates section filtering grouped cards by candidate name or email, with an empty state when nothing matches
- [x] 4.4 Test: review toggle updates the badge; rejection requires a motivation, moves to the rejected stage, and creates the conversation; search filters cards and shows an empty state

## 5. Polish, docs, and screenshots

- [x] 5.1 De-emphasize the Kanban entry on the job page (secondary styling) and confirm the Kanban still opens the board for that job
- [x] 5.2 Add per-job candidate counts to the jobs index page (`JobsLive.Index`) as a follow-on glance value
- [x] 5.3 Update `site/features/pipeline.md` and `site/features/candidate-management.md` to describe the job-page workspace, read-only pipeline overview, and contextual back navigation
- [x] 5.4 Regenerate screenshots with `node scripts/screenshots.mjs` and run `mix precommit` to fix any pending issues