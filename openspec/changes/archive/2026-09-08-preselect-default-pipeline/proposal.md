## Why

Job creation showed a "Default pipeline" placeholder followed by real pipelines (`lib/treby_web/live/jobs_live/index.ex:176`). Users were confused why an abstract "Predefinito" appeared before concrete options, and an empty selection relied on backend fallback to `Pipeline.default_pipeline_id/1`.

## What Changes

- **UI**: Job creation form preselects the tenant's default pipeline and shows only real pipelines — no placeholder prompt.
- **Behavior**: New jobs are always created with an explicit `pipeline_id` (the default unless changed). Backend fallback for empty `pipeline_id` is kept for safety/API but no longer triggered by the UI.
- **BREAKING**: None — API still accepts nil/empty and falls back; UI now never sends it.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `job-management`: `Create job posting` requirement now describes preselected default pipeline instead of empty prompt → nil.
- `pipeline-config`: `New jobs use default pipeline` scenario wording updated to match preselected UI (behavior unchanged: default pipeline is used).

## Impact

- `lib/treby_web/live/jobs_live/index.ex` (already implemented: `5282cfc`).
- Specs: `openspec/specs/job-management/spec.md`, `openspec/specs/pipeline-config/spec.md`.
- No migration, no deps.
