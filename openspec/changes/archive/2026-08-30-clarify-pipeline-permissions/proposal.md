## Why

Pipeline movement is the daily ATS action, but permissions are invisible. In live exploration at `/app/pipeline/:job_id`, a card shows `cursor-move` even when the current user is not an advancer for the target stage; drag via `phx-hook="Sortable"` only fails after drop with `You are not authorized to move candidates to this stage` (`PipelineLive.Index handle_event "move_candidate"` checks `Pipeline.user_is_advancer?` or `admin`). Advancers are assigned deep in `Settings → Pipeline → Stage → Advancers` (`Treby.Pipeline.{assign,remove}_advancer`), never surfaced in the pipeline board or onboarding. The duplicate pipeline names in the job form (`Default pipeline` + `Default`) further erode trust that the right pipeline is being used.

## What Changes

- Make pipeline permissions visible and forgiving on the board:
  - On `/app/pipeline/:job_id` (`TrebyWeb.PipelineLive.Index`): render stage headers with advancer avatars/names, and per-card move affordance (`Move to ▾` dropdown of allowed target stages) instead of relying solely on drag-drop. Disable non-allowed targets with tooltip `Only advancers for this stage can move candidates here — manage in Settings → Pipeline`.
  - Keep drag-drop (`Sortable`) for allowed moves, but show `not-allowed` cursor and pre-flight check before firing `move_candidate`.
  - In `Jobs → New Job` pipeline selector: deduplicate options — show single `Default — 7 stages` with stage count and remove the duplicate entry (`list_pipelines` vs `default_pipeline_id` conflation).
  - On `Settings → Pipeline → Stage` detail: add inline summary `This stage can be operated by: Alice (admin), Bob (advancer)` and a `Set as default pipeline` hint.

## Capabilities

### New Capabilities
- `pipeline-permission-visibility`: Board-level visibility of who can move candidates into each stage and what targets are allowed for the current user.

### Modified Capabilities
- `pipeline`: Move requirements SHALL check advancer/admin and SHALL surface allowed targets before drop; the board SHALL render advancer info per stage.
- `pipeline-stage-roles`: Advancer assignment SHALL be discoverable from the pipeline board, not only from settings.
- `job-management`: Job creation SHALL show a deduplicated pipeline selector with stage counts.

## Impact

- Affected code: `lib/treby_web/live/pipeline_live/index.ex`, `lib/treby/pipeline/pipeline.ex`, `lib/treby_web/live/jobs_live/index.ex`, `lib/treby_web/live/settings_live/pipeline.ex` + `pipeline_stages.ex`, `assets/js/hooks/sortable.js`
- No schema migration — reuses `stage_advancers` join table and `pipeline.stages`.
- Docs: update `site/features/pipeline.md` and `site/features/jobs.md` with permission model explanation; regenerate screenshots.
- Tests: extend `test/treby_web/live/pipeline_live_test.exs` to cover non-advancer disabled state and deduped selector.
