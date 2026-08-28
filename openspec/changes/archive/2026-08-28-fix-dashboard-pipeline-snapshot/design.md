## Context

`Dashboard.pipeline_snapshot/1` (in `lib/treby/dashboard.ex`, ~lines 166-195) builds per-job, per-stage counts for the dashboard Pipeline Snapshot panel. It currently filters out jobs whose `pipeline_id` is nil and resolves stages through `list_pipeline_stages(job.pipeline_id)`.

Jobs created from the New Job form keep `pipeline_id = nil` when the admin leaves the pipeline combobox on the prompt option. Under the product contract, such jobs must use the tenant's default pipeline. The context module already ships the correct helpers:

- `Pipeline.job_effective_pipeline_id/1` (pipeline.ex:212) — explicit pipeline or tenant default.
- `Pipeline.list_pipeline_stages_for_job/1` (pipeline.ex:202) — effective stages with fallback.

Public pipeline routes also apply the same effective-pipeline resolution, so the board and the dashboard must stay consistent.

## Goals / Non-Goals

**Goals:**
- Every open job appears in the dashboard pipeline snapshot with candidate counts per stage.
- Reuse the existing effective-pipeline helpers instead of duplicating resolution logic.

**Non-Goals:**
- Not changing the New Job form's pipeline combobox UX (tracked separately, see `fix-pipeline-bulk-stages`).
- Not altering dashboard panels other than Pipeline Snapshot.

## Decisions

- `pipeline_snapshot/1` resolves each open job's effective pipeline id via `job_effective_pipeline_id/1` and gets stages via `list_pipeline_stages_for_job/1`, keeping the existing "open jobs only" filter.
- Candidate counts are grouped by stage id from the effective stages, so a job whose `pipeline_id` is nil is included.
- Alternative considered: defaulting `pipeline_id` to the tenant default at job creation (data-level fix). Rejected: broader blast radius and it duplicates the fallback that helpers already provide; the snapshot-level fix is localized and keeps one source of truth.

## Risks / Trade-offs

- [Job whose effective pipeline has no stages] → Mitigation: snapshot skips the stage (renders empty counts), matching current behavior.
- [N+1 queries if stages are per-job fetched] → Mitigation: fetch default pipeline stages once and reuse; keep the snapshot query batched.