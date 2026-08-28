## Why

Open jobs created without an explicitly selected pipeline are missing from the dashboard's Pipeline Snapshot. The snapshot query filters on a non-nil `job.pipeline_id`, even though the product contract says jobs without an explicit pipeline use the tenant's default pipeline.

## What Changes

- The dashboard pipeline snapshot includes every open job, resolving each job's effective pipeline (explicit if assigned, otherwise the tenant's default pipeline).
- Candidate-per-stage counts use the job's effective pipeline stages instead of `list_pipeline_stages(job.pipeline_id)`.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `dashboard`: The "Pipeline snapshot" requirement is updated so open jobs with no explicit pipeline still appear in the pipeline overview with candidate counts.

## Impact

- `lib/treby/dashboard.ex` — `pipeline_snapshot/1` (lines ~166-195).
- `lib/treby/pipeline/pipeline.ex` — reuse existing `job_effective_pipeline_id/1` and `list_pipeline_stages_for_job/1` helpers.
- Dashboard LiveView and page rendering.