## Context

Currently `Candidates → Add Candidate` (`CandidatesLive.Index`) only creates a `Candidate` (`candidates` table) with `name/email/phone`. It does **not** create an `Application` (`applications` table) linking that candidate to a job, so the candidate never appears on any `Pipeline` board. The only way to get a candidate into a pipeline is via the public career page `/:slug/careers/:job/apply` (which calls `Candidates.create_or_find` + `Pipeline.create_application` with `anagrafica` snapshot) or CSV import. Recruiters sourcing candidates manually (referral, LinkedIn) must impersonate the public form — verified live: `Alice Dome` created via Add Candidate showed `0 applications` and `Pipeline: New 0` until a public apply was submitted.

The `applications` schema already supports internal creation: `Pipeline.create_application` handles `tenant_id/job_id/candidate_id/pipeline_stage_id/applied_at`, sets `anagrafica` via `build_anagrafica`, and flags `is_duplicate`. No migration is needed.

## Goals / Non-Goals

**Goals:**
- Let an authenticated user create a candidate **and** an application to a chosen job in one action from inside `/app`.
- Let an existing candidate without an application be linked to a job.
- Let a job/pipeline empty state attach an existing candidate to that job.
- Preserve tenant scoping (all selectors scoped to `current_tenant.id`) and `is_duplicate` semantics.

**Non-Goals:**
- No resume upload in the first iteration (public apply has it, internal can add later).
- No change to `Candidates.create_or_find` dedup logic or `pipeline_stage_id` selection beyond using the job's first stage (`New`).
- No `site/` doc changes beyond feature pages (handled as follow-up).

## Decisions

**Decision 1 — Three entry points, one service path (chosen) over a single modal.**
- *Chosen:* 
  - A) `Candidates → Add Candidate` modal gains optional `Job` select (prompt `No job — just create profile` + list of `Jobs.list_jobs`). On submit, after `Candidates.create_candidate` (or `create_or_find` if email exists), if `job_id` present, call `Pipeline.create_application` with `pipeline_stage_id = hd(list_pipeline_stages_for_job(job_id)).id`.
  - B) `Candidates → Show` (`/app/candidates/:id`) gains `Add to Job` button when `applications == []` or candidate has no app for a given job; same selector + `create_application`.
  - C) `Jobs → Show` and `Pipeline` empty state (`No applications yet`) gains `Add existing candidate` picker (search by name/email, scoped to tenant) that calls `create_application`.
- *Why:* Covers all discovery paths (sourcing vs job-centric). Single service `InternalApplication` helper wraps the two writes in a `Repo.transaction`.
- *Alternatives:* Single `Add to Job` only on `Candidates → Show` — rejected because sourcing often starts from `Candidates → Add` without visiting profile.

**Decision 2 — Use `Candidates.create_or_find` for idempotency, not raw `create_candidate`.**
- *Chosen:* The modal will call `create_or_find(tenant_id, %{"name"=>…, "email"=>…})` so email dedup returns existing candidate instead of erroring, then `create_application` will flag `is_duplicate` if the candidate already has an app for that job.
- *Why:* Matches public apply and CSV import behavior; avoids `has already been taken` errors when re-adding a known candidate to a new job.

**Decision 3 — Stage selection: first stage of job's effective pipeline.**
- *Chosen:* `pipeline_stage_id = Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()` (which falls back to default pipeline when `job.pipeline_id == nil`).
- *Why:* Reuses `P0-2` fix; `New` is always position 0. Later iterations can expose stage picker, but first stage is the expected default.

**Decision 4 — Transaction + PubSub + Activity log reuse.**
- *Chosen:* Wrap `candidate` (if new) + `application` inserts in `Repo.transaction`; on success, `Pipeline.subscribe_to_pipeline` broadcast is already handled by `create_application`? Actually `create_application` does not broadcast, but `move_application` does. For new apps, `list_applications_by_stage` will pick them up on next mount; for live boards, we can `Phoenix.PubSub.broadcast("pipeline:#{job_id}", {:pipeline_updated, job_id})` similarly to `move_application`.
- *Why:* Keeps real-time sync without adding new PubSub topics.

## Risks / Trade-offs

- **[Risk] Job selector lists closed jobs → application in closed job** → Mitigation: filter `Jobs.list_open_jobs(tenant.id)` or `where status == "open"`; show badge `Closed` if still selectable.
- **[Risk] Large tenant candidate/job lists → selector performance** → Mitigation: `list_jobs` is small (<100); candidate picker will be a search input with `Candidates.list_candidates(tenant.id, %{search: term})` debounced (already exists), not a full dropdown.
- **[Risk] Double-submit creates duplicate candidate + duplicate application** → Mitigation: `create_or_find` is idempotent on email; `is_duplicate` flag handles second app; disable submit after click.

## Migration Plan

- No migration. Deploy: `mix compile`. Rollback: revert three LiveView files.

## Open Questions

- Should the internal `Add to Job` also expose `Source` (e.g. `Manual`, `Referral`)? Deferred to `source-tracking` spec; for now set `source: "manual"`.
- Resume upload for internal adds — defer to next iteration (public apply already handles S3 via `Treby.Uploads`).
