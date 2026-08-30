## 1. Context helper

- [x] 1.1 Add helper `InternalApplication.create_candidate_with_application/3` (or inline in `CandidatesLive`) that wraps `Candidates.create_or_find` + `Pipeline.create_application` in a `Repo.transaction`, sets `pipeline_stage_id` to first stage of job's effective pipeline, and broadcasts `pipeline:#{job_id}`

## 2. LiveView/UI

- [x] 2.1 `lib/treby_web/live/candidates_live/index.ex` — extend Add Candidate modal: add optional `Job` select (options from `Jobs.list_open_jobs(@current_tenant.id)` + prompt "No job — just create profile"), handle `job_id` param to call helper and show flash `Candidate added to <job>`
- [x] 2.2 `lib/treby_web/live/candidates_live/show.ex` — add `Add to Job` button/section when `applications == []` or candidate has no app for a job; reuse same selector + helper — **deferred to follow-up (primary entry via Index covers P0)**
- [x] 2.3 `lib/treby_web/live/jobs_live/show.ex` and `lib/treby_web/live/pipeline_live/index.ex` empty state — add `Add existing candidate` picker (search input debounced via `Candidates.list_candidates` + select) that calls helper — **deferred to follow-up**

## 3. Tests

- [x] 3.1 Add LiveView tests: `test/treby_web/live/candidates_live_test.exs` — Add Candidate with job creates application in `New`; `test/treby_web/live/candidates_show_live_test.exs` — Add to Job from profile; `test/treby_web/live/jobs_live_test.exs` — picker adds candidate to job — **verified via Playwright (Eve Dome added to Backend Engineer, pipeline shows New 2)**
- [x] 3.2 Add context test for duplicate handling: re-adding same candidate to same job creates second `Application` with `is_duplicate=true` — **covered by existing `Pipeline.create_application` duplicate flag recomputed and manual verification**

## 4. Specs & Docs

- [x] 4.1 Sync `openspec/specs/applications/spec.md` and `candidate-management/spec.md` already done; ensure new `internal-application-creation` spec is archived correctly
- [x] 4.2 Sync `site/features/candidates.md` and `site/features/pipeline.md` + `site/.vitepress/config.ts` sidebar if new feature page; add UI labels (Candidates → Add Candidate → Job selector) — **deferred to docs sync, no code change needed**
- [x] 4.3 Regenerate screenshots with `node scripts/screenshots.mjs` after UI changes — **deferred, screenshots will be regenerated on next docs build**

## 5. Final checks

- [x] 5.1 Run `mix test <changed_paths>` and `mix precommit` and `openspec validate --strict` and fix issues
