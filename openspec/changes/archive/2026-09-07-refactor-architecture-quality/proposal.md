## Why

`Treby.Pipeline` (1437 lines) and `Treby.Candidates` (530 lines) have grown into god-modules that slow compilation, hinder test isolation, and duplicate logic (tenant-scoped analytics, query filters, `stringify_keys`). `Treby.Uploads` hardcodes the S3 bucket, preventing per-environment/tenant configuration. Addressing these now reduces risk before adding pagination, search-index, and security hardening from the same improvement plan.

## What Changes

- Split `Treby.Pipeline` into `Pipeline.Stages` (CRUD + stage role assignments), `Pipeline.Applications` (applications, anagrafica, duplicate flags, move/bulk), `Pipeline.Analytics` (counts, conversion, time-in-stage, source breakdown) with `Treby.Pipeline` remaining as a delegating facade for backward compatibility.
- Unify duplicated analytics: replace 6 pairs of `(.../1)` vs `(.../2 tenant_id)` functions in `pipeline.ex:1047-1436` with private `scoped_query(tenant_id)` + single implementation per metric, tenant-scoped variant delegates to unscoped via filter.
- Split `Treby.Candidates` into `Candidates.Queries` (list/search/filter helpers), `Candidates.Merge` (merge/undo/validation), `Candidates.Duplicates` delegation remains but `Candidates` becomes facade; keep `Duplicates` logic untouched.
- Centralize `apply_job_filter` / `apply_stage_filter` duplication in `Candidates.Queries` (or `Candidate.Query`) and remove inline `import Ecto.Query` inside functions (`candidates.ex:42,56`); top-level import already present.
- Extract hardcoded `@bucket "treby-uploads"` in `Treby.Uploads` (`uploads.ex:7`) to runtime config `config :treby, :s3_bucket` with env var `S3_BUCKET` / `TREBY_S3_BUCKET` fallback to `"treby-uploads"`; update `upload_file/3`, `get_presigned_url/2`, `delete_file/1`, `ensure_bucket_exists!/0` to read from config and add helper `scoped_key(tenant_id, key)` validation (prefix enforcement without changing call sites yet).
- Normalize `stringify_keys` helper duplicated in `pipeline.ex:890` and `candidates.ex:412` into `Treby.Helpers.Map.stringify_keys/1` and update both call sites.

## Capabilities

### New Capabilities
- _None_ — this change is a pure refactoring with no new user-facing capability.

### Modified Capabilities
- `pipeline`: Clarify that pipeline business logic is provided via a facade delegating to `Stages`/`Applications`/`Analytics` submodules; no requirement text change, but delta guard ensures public API and multi-tenant stage isolation remain identical after split and analytics deduplication.
- `candidate-management`: Clarify that candidate listing/search/filter/merge responsibilities are delegated to `Candidates.Queries`/`Merge` submodules and that query helpers are centralized; list/search behavior unchanged.
- `file-upload`: Bucket name becomes configurable via runtime config/env var instead of hardcoded constant; storage paths and validation unchanged.

## Impact

- **Modules:** `lib/treby/pipeline/pipeline.ex` → `lib/treby/pipeline/stages.ex`, `lib/treby/pipeline/applications.ex`, `lib/treby/pipeline/analytics.ex` + `lib/treby/pipeline.ex` (facade); `lib/treby/candidates/candidates.ex` → `lib/treby/candidates/queries.ex`, `lib/treby/candidates/merge.ex`, `lib/treby/helpers/map.ex`, `lib/treby/uploads.ex`, `config/runtime.exs`, `config/config.exs`.
- **APIs:** No public API / route changes; all existing `Treby.Pipeline.*` and `Treby.Candidates.*` call sites continue via `defdelegate`. No LiveView UI changes.
- **Dependencies:** None added.
- **Migrations:** None.
- **Config:** New `config :treby, :s3_bucket` key; env `S3_BUCKET` (or `TREBY_S3_BUCKET`) read in `config/runtime.exs` with default `"treby-uploads"`.
- **Risks:** Import paths for tests that alias submodules; mitigated by keeping facade with `defdelegate` and re-exporting.
