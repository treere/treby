## Why

Rejecting a candidate cannot complete for any tenant using the default pipeline. The default pipeline has no terminal rejected stage, and the board/profile reject handlers resolve stages through a nil `pipeline_id` or by matching the stage *name*, so they never find a target stage.

## What Changes

- The tenant's default pipeline includes a terminal stage with `stage_type = "rejected"`.
- Board reject (`pipeline_live/index.ex:887-977`) resolves stages via the job's effective pipeline (`list_pipeline_stages_for_job/1`) instead of `list_pipeline_stages(job.pipeline_id)`.
- Profile reject (`candidates_live/show.ex:1228-1293`) finds the rejected stage by `stage_type` on the job's effective pipeline and guards against a candidate with no applications.
- Rejection targets the stage by type (`stage_type = "rejected"`), never by name.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `pipeline-config`: A rejected-type stage is guaranteed in the default pipeline; rejection targets the rejected type.
- `pipeline`: The "Advance or reject candidate from stage" flow works for jobs without an explicit pipeline.
- `candidate-management`: Rejecting from the candidate profile resolves the rejected stage reliably and is safe for candidates without applications.

## Impact

- `lib/treby/pipeline/pipeline.ex` — `create_default_pipeline_stages/1`.
- `lib/treby_web/live/pipeline_live/index.ex` — `confirm_reject`.
- `lib/treby_web/live/candidates_live/show.ex` — `submit_rejection`.
- Data migration to add the rejected stage to existing default pipelines.