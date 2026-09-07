## Why

With architecture, security, and performance done, the remaining correctness risks are silent failure modes and races: `move_application` swallows notification errors (`rescue/catch → :ok`), `detach_job_pipeline` checks sharing then clones without a lock, and a few small data-integrity gaps (duplicate-flag double write, `visible=true` on closed jobs, per-row candidate fetch). All are S-sized, user-invisible fixes that prevent real production incidents.

## What Changes

- `move_application` SHALL log notification failures via `Logger.warning` and emit a `:telemetry` event instead of returning `:ok` silently (behavior otherwise unchanged, still non-blocking).
- `detach_job_pipeline` SHALL run the share-check + clone + remap inside a `Repo.transaction` with a `FOR UPDATE` lock on the pipeline row, so a concurrent attach cannot slip between check and clone.
- `recompute_duplicate_flags` SHALL reset + set flags in a single `update_all` with a `CASE` expression.
- `create_application` SHALL accept a preloaded candidate (new optional `:candidate` opt) to skip the per-row `Repo.get` in `ensure_anagrafica`; callers that already have the candidate pass it.
- `Job` changeset SHALL reject `visible=true` when `status="closed"` (`validate_visible_requires_open`).
- Remove the 3 remaining function-level `import Ecto.Query` in LiveViews (`candidates_live/show.ex`, `jobs_live/index.ex`, `jobs_live/show.ex`) in favor of top-level imports.
- No UI, route, API, or migration changes.

## Capabilities

### New Capabilities
- _None_ — all items harden existing behavior.

### Modified Capabilities
- `applications`: stage-change notification failures SHALL be observable (log + telemetry) instead of silent.
- `pipeline`: pipeline detach SHALL be race-safe under concurrent attaches.
- `applications`: duplicate-flag recompute SHALL be a single write query.
- `applications`: application creation SHALL avoid the per-row candidate fetch when the caller has the record.
- `job-management`: closed jobs SHALL NOT be markable visible.

## Impact

- **Modules:** `lib/treby/pipeline/applications.ex` (notify logging, recompute query, `:candidate` opt), `lib/treby/pipeline/stages.ex` (detach transaction + lock), `lib/treby/jobs/job.ex` (visible/status validation), 3 LiveView files (import hoisting).
- **APIs:** None.
- **Dependencies:** None (`:telemetry` ships with Phoenix).
- **Migrations:** None.
- **Config:** None.
- **Risks:** The new `visible/status` validation could reject previously-persistable combos — existing closed+visible rows are untouched (validation runs on changeset only); a `detect` mix task is NOT included (no evidence of such rows; keep scope tight).
