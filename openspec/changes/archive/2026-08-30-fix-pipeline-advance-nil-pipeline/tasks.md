## 1. Fix advance handler effective pipeline

- [x] 1.1 In `lib/treby_web/live/pipeline_live/index.ex` `handle_event "advance_application"`, replace `Pipeline.list_pipeline_stages(job.pipeline_id)` with `Pipeline.list_pipeline_stages_for_job(job.id)` (or `Pipeline.list_pipeline_stages(Pipeline.job_effective_pipeline_id(job))`)
- [x] 1.2 Audit other direct `list_pipeline_stages(job.pipeline_id)` calls in the same LiveView for the same fix
- [x] 1.3 In `lib/treby_web/live/jobs_live/index.ex` (or `Treby.Jobs.create_job`), default blank `pipeline_id` to `Pipeline.default_pipeline_id(tenant.id)` to avoid persisting `nil`

## 2. Tests

- [x] 2.1 Extend `test/treby_web/live/pipeline_live_test.exs`: add `advance_application` case for a job with `pipeline_id == nil` that has a completed interview + scorecard and asserts the application moves to the next stage (e.g., Interview → Offer)
- [x] 2.2 Run `mix test test/treby_web/live/pipeline_live_test.exs` and `mix precommit`

## 3. Verification

- [x] 3.1 Playwright smoke: `Friction Co 86` job `Backend Engineer` (`pipeline_id == nil`, Hired 1) reset to Interview, then `Advance` via `/app/pipeline/:job_id` moves to `Offer` without `ArgumentError` and shows flash
