## Context

`PipelineLive.Index` (`lib/treby_web/live/pipeline_live/index.ex`) renders the Kanban at `/app/pipeline/:job_id`. The board itself loads correctly for jobs without an explicit `pipeline_id` because `mount/3` uses the tenant-safe helper:

```elixir
applications_by_stage = Pipeline.list_applications_by_stage(job_id)
stages = Pipeline.list_pipeline_stages_for_job(job.id)  # falls back to default_pipeline_id
```

`Treby.Pipeline.job_effective_pipeline_id/1` and `job_effective_pipeline/1` encapsulate this fallback. However, the **advance** path broke the contract:

```elixir
# handle_event "advance_application" :1107
job = Jobs.get_job!(tenant.id, application.job_id)
stages = Pipeline.list_pipeline_stages(job.pipeline_id)  # ← nil when job created via UI
current_idx = Enum.find_index(stages, &(&1.id == stage.id))
next_stage = Enum.at(stages, current_idx + 1)
```

Jobs created via `JobsLive.Index` (`+ New Job` form) save `pipeline_id == nil` — the `Pipeline` select shows duplicate `Default` entries and defaults to blank. `job.pipeline_id` is therefore `nil` for `Backend Engineer 6dc4efc5…` in `Friction Co 86`. The board renders (uses `list_pipeline_stages_for_job`), but `Advance` raises `ArgumentError comparing ps.pipeline_id with nil is forbidden` at `Pipeline.list_pipeline_stages(nil)`. The candidate (Alice) stays stuck in `Interview` despite `Ready to advance`.

No tenant isolation issue — `list_pipeline_stages_for_job` already scopes via the job's tenant — but the inconsistent use of the helper vs raw column is the bug.

## Goals / Non-Goals

**Goals:**
- `Advance` (Interview → Offer → Hired) works for jobs with `pipeline_id == nil` by resolving the effective pipeline.
- Keep the existing stage-order logic (`position` ascending, `current_idx + 1`) and `Ready to advance` gate (`ready_to_advance?` with scorecards) unchanged.
- Fix the duplicate `Default` entry in the job creation `Pipeline` select to avoid persisting `nil` going forward.

**Non-Goals:**
- No migration to backfill `nil` pipeline_ids (handled by fallback).
- No `site/` doc changes, no new dependencies.
- No change to drag-drop (`move_candidate`) — it already uses `list_pipeline_stages_for_job` correctly for rendering.

## Decisions

**Decision 1 — Use `list_pipeline_stages_for_job/1` in the advance handler (chosen) over patching `list_pipeline_stages/1` to handle nil.**
- *Chosen:* Replace `Pipeline.list_pipeline_stages(job.pipeline_id)` with `Pipeline.list_pipeline_stages_for_job(job.id)` (or `Pipeline.list_pipeline_stages(Pipeline.job_effective_pipeline_id(job))`).
- *Why:* Reuses the tested tenant-safe helper that already encapsulates the `default_pipeline_id` fallback. Single call site, minimal diff, no `is_nil` guard scattered in the generic `list_pipeline_stages` which should remain strict.
- *Alternatives considered:*
  - A) Guard `list_pipeline_stages(nil)` to return `[]` or default stages — rejected because it hides the bug and changes a low-level API used elsewhere.
  - B) Always persist `pipeline_id` at job creation — also done (Decision 2) but not sufficient alone for existing rows with `nil`.

**Decision 2 — Default job creation to the tenant's default pipeline when the form leaves `pipeline_id` blank.**
- *Chosen:* In `JobsLive.Index` `handle_event "save"` (or `Treby.Jobs.create_job/1` fallback), if `attrs["pipeline_id"]` is `""` or `nil`, set it to `Treby.Pipeline.default_pipeline_id(tenant.id)` before insert.
- *Why:* Prevents new `nil` rows; keeps `job.pipeline_id` explicit. Existing `nil` rows still handled by Decision 1.
- *Alternative:* Migration to backfill `nil` → default — rejected for hotfix scope; fallback already covers reads.

**Decision 3 — Scope via `job.id` not `pipeline_id` for stage lookup.**
- *Chosen:* The advance lookup uses `job.id` to get ordered stages, so tenant isolation is via `list_pipeline_stages_for_job` which loads the job and its effective pipeline.
- *Why:* Matches `mount` and avoids passing raw `pipeline_id` through the LiveView.

## Risks / Trade-offs

- **[Risk] Job with `nil` pipeline and no default pipeline (edge: tenant deleted default)** → `default_pipeline_id == nil` → `list_pipeline_stages(nil)` again → same crash → Mitigation: `list_pipeline_stages_for_job` already handles `nil` effective id by falling back to empty list; advance will then `put_flash "No next stage"` (existing branch `else → No next stage found`).
- **[Risk] Duplicate `Default` in select hides the fix** → Mitigation: deduplicate the select options to single `Default — 7 stages` entry; if blank submitted, Decision 2 fills it.
- **[Risk] `Pipeline.list_pipeline_stages_for_job` does an extra `Repo.get!` for the job** → Mitigation: negligible (already have `job`); no N+1, single query.

## Migration Plan

- No migration. Deploy: `mix compile`. Rollback: revert two call sites.

## Open Questions

- Should the `Pipeline` select in `JobsLive.Index` be a single disabled `Default` when only one pipeline exists, or a full list? Decision 2 covers the blank case; UI deduplication is follow-up if needed.
