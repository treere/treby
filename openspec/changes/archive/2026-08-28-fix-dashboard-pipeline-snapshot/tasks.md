## 1. Fix pipeline snapshot query

- [x] 1.1 Update `Dashboard.pipeline_snapshot/1` in `lib/treby/dashboard.ex` to include open jobs with a nil `pipeline_id`
- [x] 1.2 Resolve each job's effective pipeline via `Pipeline.job_effective_pipeline_id/1`
- [x] 1.3 Resolve stages via `Pipeline.list_pipeline_stages_for_job/1` instead of `list_pipeline_stages(job.pipeline_id)`
- [x] 1.4 Keep the "open jobs only" filter and empty-state behavior unchanged

## 2. Verify

- [x] 2.1 Add a test: a job with no explicit pipeline appears in the dashboard snapshot with default-pipeline stage counts
- [x] 2.2 Run the dashboard-related tests (`mix test test/treby/dashboard_test.exs`, or the appropriate test file)
- [x] 2.3 Run `mix precommit` and fix any pending issues