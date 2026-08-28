## 1. Populate bulk stages per job

- [x] 1.1 Replace the `mount` call `Pipeline.list_pipeline_stages(tenant.id)` in `pipeline_live/index.ex` with per-job stage resolution via `Pipeline.list_pipeline_stages_for_job/1`
- [x] 1.2 Populate `@stages` from the currently viewed job's effective pipeline (re-fetch on job param change)
- [x] 1.3 Disable "Move to Stage" in the bulk action bar when the effective stage list is empty

## 2. Fix list_pipeline_stages callers

- [x] 2.1 Fix the import flow (`import_live/index.ex`) to use the tenant's default pipeline stages instead of passing a tenant id to `list_pipeline_stages/1`
- [x] 2.2 Leave `list_pipeline_stages/1` semantics unchanged (pipeline-id based)

## 3. Verify

- [x] 3.1 Add a test: bulk move dropdown lists default pipeline stages for a job with no explicit pipeline
- [x] 3.2 Add a test: "Move to Stage" is disabled when the effective pipeline has no stages
- [x] 3.3 Run `mix precommit` and fix any pending issues