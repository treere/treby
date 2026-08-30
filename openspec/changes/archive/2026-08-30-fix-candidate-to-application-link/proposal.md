## Why

Manual candidate creation (`Candidates → Add Candidate`) does not create an Application, so a sourced candidate never appears in any job pipeline. Recruiters must impersonate the public career page (`/:tenant_slug/careers/:job/apply`) to place a candidate into a job — an undiscoverable workaround confirmed live at `localhost:4000` (Alice Dome created → `0 applications` → pipeline showed `0` until public apply was used). This blocks the core ATS flow: source → assign to job → move through pipeline → interview → offer/reject.

## What Changes

- Add a first-class internal path to link a candidate to a job as a new Application from within the authenticated app (no public-page impersonation).
  - Extend the `Add Candidate` modal (`/app/candidates`) with an optional `Job` selector that creates the candidate *and* an Application in the job's initial stage (`New`) with an `anagrafica` snapshot in one submit.
  - Add an `Add to Job` action on `Candidates → Show` (`/app/candidates/:id`) for existing candidates without applications (or with applications to other jobs), with job selector + optional resume upload.
  - Add an `Add existing candidate` picker on `Jobs → Show` and `Pipeline` (`/app/pipeline/:job_id` empty state) to select/attach an existing tenant candidate to that job.
- Deduplication: reuse `Candidates.create_or_find` / `Pipeline.create_application` duplicate flag (`is_duplicate`) so re-adding a candidate to the same job creates a second Application flagged as duplicate rather than erroring.
- Preserve tenant isolation: all selectors are scoped to `current_tenant.id`; job list comes from `Jobs.list_jobs(tenant_id)`.
- Add empty-state affordances: when pipeline has `No applications yet`, show `Add candidate to this job` CTA alongside drag-and-drop hint.

## Capabilities

### New Capabilities
- `internal-application-creation`: UI and service path for an authenticated user to create an Application linking an existing or new candidate to a specific job from inside `/app`, including validation, anagrafica snapshotting, and duplicate handling.

### Modified Capabilities
- `applications`: Extend "Manual application creation" requirement to cover the new internal UI entry points (modal selector, candidate show action, job/pipeline picker) — not only via career page or CSV.
- `candidate-management`: Clarify that `Create candidate` alone does not create an application; the profile page SHALL expose `Add to Job` when the candidate has no application.

## Impact

- Affected code: `lib/treby_web/live/candidates_live/index.ex`, `lib/treby_web/live/candidates_live/show.ex`, `lib/treby_web/live/jobs_live/show.ex`, `lib/treby_web/live/pipeline_live/index.ex`, `lib/treby/candidates/candidates.ex`, `lib/treby/pipeline/pipeline.ex`, `lib/treby/jobs/jobs.ex`
- No schema migration — reuses `applications` table (`candidate_id`, `job_id`, `pipeline_stage_id`, `anagrafica`, `is_duplicate`).
- Docs: update `site/features/candidates.md` and `site/features/pipeline.md` to describe the new internal apply flow; regenerate screenshots with `node scripts/screenshots.mjs`.
- Tests: extend `test/treby_web/live/candidates_live_test.exs` and `pipeline_live_test.exs` to cover internal linking and duplicate flag.
