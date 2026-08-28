## Context

`Pipeline.list_pipeline_stages/1` (pipeline.ex:195) filters stages by *pipeline id*. The pipeline LiveView `mount` (pipeline_live/index.ex:~13) calls it with the `tenant.id`, which never matches a pipeline id, so `@stages` is always `[]`. The bulk "Move to Stage" dropdown is driven by `@stages` and is therefore always empty. In addition, for jobs whose `pipeline_id` is nil there was no stage list at all.

The import flow (`import_live/index.ex`) makes the same mistake, calling `list_pipeline_stages` with a tenant id.

## Goals / Non-Goals

**Goals:**
- Bulk "Move to Stage" dropdown lists the stages of the job's effective pipeline.
- Disable the action (not show an empty dropdown) when no stages exist.
- Fix all callers that pass a tenant id to `list_pipeline_stages/1`.

**Non-Goals:**
- Not changing `list_pipeline_stages/1` semantics (it remains pipeline-id based); the bug was in callers.
- Not altering the bulk move execution transaction.

## Decisions

- The pipeline board sets the bulk stage list per job via `Pipeline.list_pipeline_stages_for_job/1` (which resolves the effective pipeline: explicit id, else tenant default). Since the board already knows the effective pipeline id per job, populate `@stages` in `handle_params`/`mount` for the current job.
- Keep `list_pipeline_stages/1` unchanged; fix the import flow to use the tenant's default pipeline stages instead of passing the tenant id.
- Guard the bulk bar: "Move to Stage" is disabled when the effective stage list is empty.

## Risks / Trade-offs

- [Stale `@stages` when the user navigates between jobs] → Mitigation: re-fetch on every job param change; a single query per job is negligible.
- [Default pipeline with zero stages in a fresh tenant] → Mitigation: disabled action with a clear tooltip, consistent with the disabled-state decision.