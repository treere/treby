## Why

Jobs created via `JobsLive.Index` (`+ New Job` form) are saved with `pipeline_id == nil` (the `Pipeline` select shows duplicate `Default` entries and defaults to no explicit id). Later, `PipelineLive.Index` displays the board correctly via `list_pipeline_stages_for_job/1` which falls back to `default_pipeline_id`, so the bug is hidden until the user clicks `Advance` on an Interview card. Then `handle_event "advance_application"` (`pipeline_live/index.ex:1107`) does `Pipeline.list_pipeline_stages(job.pipeline_id)` with `nil`, raising `ArgumentError comparing ps.pipeline_id with nil is forbidden`. The candidate is stuck in Interview despite being `Ready to advance`.

## What Changes

- Fix the pipeline lookup in `TrebyWeb.PipelineLive.Index.handle_event "advance_application"` to use the effective pipeline, not the raw column:
  - Replace `stages = Pipeline.list_pipeline_stages(job.pipeline_id)` with `stages = Pipeline.list_pipeline_stages_for_job(job.id)` or `stages = Pipeline.list_pipeline_stages(Pipeline.job_effective_pipeline_id(job))`.
  - Apply the same fix to any other direct `list_pipeline_stages(job.pipeline_id)` calls in that LiveView.
- Optionally in `Jobs.create_job` / `JobsLive.Index` form handling: default `pipeline_id` to `default_pipeline_id` when blank, to avoid `nil` persistence — decision in `design.md`.
- No change to `Pipeline` stage-move semantics; tenant isolation preserved.

## Capabilities

### New Capabilities
- _None_ — hotfix.

### Modified Capabilities
- `pipeline`: Advancing an application SHALL resolve the job's effective pipeline (explicit or default) instead of assuming `job.pipeline_id` is present; the Interview → Offer/Hired transition SHALL not crash when the job was created without an explicit pipeline.

## Impact

- Affected code: `lib/treby_web/live/pipeline_live/index.ex` (advance handler), possibly `lib/treby_web/live/jobs_live/index.ex` (job creation default), `lib/treby/pipeline/pipeline.ex` helpers
- No migration.
- Tests: extend `test/treby_web/live/pipeline_live_test.exs` already covers `rejects a candidate end-to-end for a job with no explicit pipeline` — add `advance_application` case for nil-pipeline job with scorecard + completed interview.
