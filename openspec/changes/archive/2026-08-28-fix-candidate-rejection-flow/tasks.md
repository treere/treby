## 1. Seed rejected stage in default pipeline

- [x] 1.1 Append a terminal "Rejected" stage with `stage_type = "rejected"` in `Pipeline.create_default_pipeline_stages/1` (pipeline.ex:668-692)
- [x] 1.2 Add an idempotent migration backfilling a rejected-type stage onto existing default pipelines that lack one

## 2. Fix board reject

- [x] 2.1 In `pipeline_live/index.ex` `confirm_reject` (line ~912), resolve stages via `Pipeline.list_pipeline_stages_for_job/1`
- [x] 2.2 Pick the target stage by `stage_type == "rejected"` (not by name)
- [x] 2.3 Fall back to a clear disabled-state/message when no rejected stage exists

## 3. Fix profile reject

- [x] 3.1 In `candidates_live/show.ex` `submit_rejection` (line ~1255), resolve the rejected stage via the job's effective pipeline and `stage_type`
- [x] 3.2 Guard the handler when the candidate has no applications (return a clear error instead of crashing)

## 4. Verify

- [x] 4.1 Add a test: reject works end-to-end for a job with no explicit pipeline
- [x] 4.2 Add a test: profile reject for a candidate without applications does not crash
- [x] 4.3 Run `mix precommit` and fix any pending issues