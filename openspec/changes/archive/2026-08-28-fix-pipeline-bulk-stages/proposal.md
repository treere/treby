## Why

The "Move to Stage" dropdown in the pipeline bulk action bar is always empty. The pipeline LiveView `mount` loads stages by calling `Pipeline.list_pipeline_stages(tenant.id)`, but that function expects a pipeline id (not a tenant id), so it returns an empty list.

## What Changes

- The pipeline board resolves bulk-move stages from the currently viewed job's effective pipeline (`list_pipeline_stages_for_job/1`), populated per job.
- The bulk action bar disables "Move to Stage" when the effective pipeline has no stages, instead of showing an empty dropdown.
- Callers that misuse `list_pipeline_stages/1` (passing a tenant id) are corrected, notably in the import flow.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `bulk-operations`: "Bulk move via action bar" lists the effective pipeline's stages.
- `pipeline`: "Bulk move candidates" dropdown is populated for jobs with or without an explicit pipeline.

## Impact

- `lib/treby_web/live/pipeline_live/index.ex` (mount line ~13 and bulk move handler).
- `lib/treby/pipeline/pipeline.ex` (`list_pipeline_stages/1` contract stays pipeline-id based).
- `lib/treby_web/live/import_live/index.ex` (misuse of `list_pipeline_stages`).