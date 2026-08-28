## Context

`Pipeline.create_default_pipeline_stages/1` (pipeline.ex:668-692) seeds the default pipeline with New, Screen, Phone Screen, Interview, Offer, Hired — there is no rejected stage. Stage types are already first-class (`stage_type` on stages; the pipeline-config spec allows type "rejected"), but the reject handlers look for a stage named "Rejected":

- Board: `pipeline_live/index.ex:912` calls `Pipeline.list_pipeline_stages(job.pipeline_id)` — with `pipeline_id = nil` this returns `[]` and the UI reports "No rejected stage found in this pipeline".
- Profile: `candidates_live/show.ex:1255` does `Enum.find(job.pipeline_stages, &(&1.name == "Rejected"))` — brittle (name-based) and fails when the stage is named differently or `pipeline_stages` is not preloaded.

## Goals / Non-Goals

**Goals:**
- Rejection completes end-to-end for every default-pipeline job.
- Rejected stage is located by `stage_type = "rejected"`, never by name.
- Profile reject is safe when the candidate has no applications.

**Non-Goals:**
- Not changing the portal rejection message/notification content.
- Not adding a rejection workflow redesign (approval flows etc.).

## Decisions

- `create_default_pipeline_stages/1` appends a final stage `"Rejected"` with `stage_type = "rejected"`.
- Board `confirm_reject` resolves stages via `Pipeline.list_pipeline_stages_for_job/1` and picks the stage whose `stage_type == "rejected"`.
- Profile `submit_rejection` uses the same resolution helper + `stage_type` lookup, and returns a flash error instead of crashing when there is no application.
- Add a data migration that backfills a rejected-type stage onto existing default pipelines that lack one (idempotent).

## Risks / Trade-offs

- [Existing tenants already have default pipelines without a rejected stage] → Mitigation: idempotent migration backfilling the stage.
- [Custom pipelines without a rejected-type stage] → Mitigation: reject UI explains a rejected stage is required and disables the action, rather than failing silently.

## Open Questions

- Should the rejected stage also be exposed for portal candidates to see the rejection reason? (Out of scope; portal rejection UX unchanged.)