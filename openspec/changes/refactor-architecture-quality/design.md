## Context

`Treby.Pipeline` (`lib/treby/pipeline/pipeline.ex:1`, 1437 lines) bundles pipeline CRUD, stage CRUD and role assignments, application creation/progress, and analytics (counts, conversion, time-in-stage, source breakdown) in one module. `Treby.Candidates` (`lib/treby/candidates/candidates.ex:1`, 530 lines) bundles listing/search, creation/dedup, merge/undo, and duplicate suggestion handling. Both are god-modules: slow to compile, hard to test in isolation, and prone to duplication.

Duplication is already visible:
- Analytics has 6 function pairs `fn/1` vs `fn/2 tenant_id` (`pipeline.ex:1047-1436`) differing only by tenant filter; a private `scoped_query` is missing.
- `Candidates.apply_job_filter` and `apply_stage_filter` re-import `Ecto.Query` inline (`candidates.ex:42,56`) despite top-level import.
- `stringify_keys` is duplicated (`pipeline.ex:890`, `candidates.ex:412`).
- `Treby.Uploads` hardcodes `@bucket "treby-uploads"` (`uploads.ex:7`) with no env/config override, blocking per-environment or per-tenant bucket naming.

Stakeholders: backend devs, CI (compile/test speed), self-hosted operators (S3 config).

## Goals / Non-Goals

**Goals:**
- Split god-modules into focused submodules with `Treby.Pipeline` and `Treby.Candidates` as backward-compatible facades (zero call-site churn).
- Deduplicate analytics via `scoped_query(tenant_id)` helper so `(.../2)` delegates to `(.../1)` filtered path.
- Centralize candidate query helpers in `Candidates.Queries` and remove inline imports.
- Make S3 bucket runtime-configurable (`config :treby, :s3_bucket`) while preserving default `"treby-uploads"`.
- Extract `stringify_keys` to `Treby.Helpers.Map` and reuse from both contexts.

**Non-Goals:**
- No pagination, search-index, or security hardening (separate changes per `IMPROVEMENTS.md:33` and `IMPROVEMENTS.md:20`).
- No schema/migration changes, no new UI/routes, no new dependencies.
- No change to `Treby.Candidates.Duplicates` algorithm (only wiring).

## Decisions

**Decision 1: Facade + `defdelegate` for Pipeline and Candidates**
- Split Pipeline → `Treby.Pipeline.Stages` (pipelines, templates, stages, role assignments), `Treby.Pipeline.Applications` (applications, anagrafica, duplicate flags, `move_application`, bulk), `Treby.Pipeline.Analytics` (all analytics). Candidates → `Treby.Candidates.Queries` (list/search/filter helpers) and `Treby.Candidates.Merge` (merge/undo/validation). Top-level `Treby.Pipeline` and `Treby.Candidates` keep public API via `defdelegate`.
- *Rationale:* Zero breaking change; existing tests and LiveViews keep `alias Treby.Pipeline` imports. Allows incremental test isolation per submodule.
- *Alternative considered:* Rename call sites to submodules directly — rejected, causes ~80 file churn and merge conflicts.

**Decision 2: Analytics `scoped_query` helper**
- Private `scoped_pipeline_ids(tenant_id)` and `scoped_application_query(tenant_id)` helpers in `Analytics` return base query filtered by tenant when `tenant_id` is not nil; `pipeline_counts_per_stage/2`, `average_time_to_hire/2`, `stage_conversion_rates/2`, `source_breakdown/2` delegate to single implementation.
- *Rationale:* Eliminates 6 duplicated branches; mirrors existing pattern in `pipeline_counts_per_stage_for_job/1:1085` (single `group_by` query).
- *Alternative:* Two modules `Analytics.Global` vs `Analytics.Tenant` — rejected, doubles API surface.

**Decision 3: Candidates query centralization**
- `Candidates.Queries` exposes `apply_search/2`, `apply_job_filter/2`, `apply_stage_filter/2`, and `base_active_query/1`. Removes `import Ecto.Query` inside functions; top-level import only.
- *Rationale:* Single place to add `escape_like` or pagination later (`IMPROVEMENTS.md:35`).
- *Alternative:* `Candidate.Query` schema module — rejected, schema already owns changeset; query helpers belong to context.

**Decision 4: S3 bucket via `config :treby, :s3_bucket`**
- Default `config :treby, s3_bucket: "treby-uploads"` in `config/config.exs`; override in `config/runtime.exs` via `Env.env("S3_BUCKET") || Env.env("TREBY_S3_BUCKET")`. `Treby.Uploads` reads `Application.get_env(:treby, :s3_bucket)` (or `Application.fetch_env!`) at runtime, not compile-time. Add `scoped_key(tenant_id, key)` that ensures `key` starts with `"#{tenant_id}/"` else raises.
- *Rationale:* Runtime config enables per-env bucket without recompilation; test env keeps default; helper enforces tenant scoping noted in `IMPROVEMENTS.md:25` without changing external contract yet.
- *Alternative:* Per-tenant bucket map — rejected, out of scope until multi-bucket S3 needed.

**Decision 5: Helpers.Map extraction**
- New `Treby.Helpers.Map.stringify_keys/1` (`lib/treby/helpers/map.ex`) used from `Pipeline.Applications` and `Candidates.Merge`. Keeps impl `Map.new(attrs, fn {k,v} -> {to_string(k), v} end)` as before.
- *Rationale:* Single helper; also usable for future `stringify_keys` in `Treby.Jobs` if needed.
- *Alternative:* `Treby.Helpers` generic — rejected, keep bounded namespace.

## Risks / Trade-offs

- **Stale facade after split** → Mitigation: `Treby.Pipeline` and `Treby.Candidates` re-export via `defdelegate` and are covered by existing 522 tests; compile fails if delegate target missing.
- **Analytics tenant scoping regression** → Mitigation: add property-style test that `pipeline_counts_per_stage(nil)` and `pipeline_counts_per_stage(tenant_id, nil)` return identical counts when tenant owns all data; existing analytics tests run unchanged.
- **Config key divergence between compile and runtime** → Mitigation: read bucket at runtime via `Application.get_env`; add test asserting `Treby.Uploads.bucket/0` reflects runtime override.
- **Circular deps Pipeline ↔ Candidates** (`recompute_duplicate_flags`) → Mitigation: keep `recompute_duplicate_flags` in `Pipeline.Applications` and have `Candidates.Merge` call it via `Treby.Pipeline` facade (no direct submodule cross-import).

## Migration Plan

1. Create new modules (`stages.ex`, `applications.ex`, `analytics.ex`, `queries.ex`, `merge.ex`, `helpers/map.ex`) with functions moved verbatim; keep `lib/treby/pipeline/pipeline.ex` and `lib/treby/candidates/candidates.ex` as facades.
2. Update `config/config.exs` and `config/runtime.exs` for `s3_bucket`; update `Treby.Uploads` to read config + add `scoped_key/2` (not yet enforced on `put_object` call sites — additive).
3. Update internal call sites to use `Helpers.Map.stringify_keys`; remove inline `import Ecto.Query`.
4. Run `mix compile --warnings-as-errors`, `mix test`, `mix precommit`; verify no `grep -R "def stringify_keys"` duplicates remain.
5. Rollback: revert facade to original monolith files (git revert single commit); no migration to roll back.

## Open Questions

- Should `scoped_key/2` be enforced immediately in `upload_file/3` / `get_presigned_url/2` or only added as helper for next security change (`IMPROVEMENTS.md:25`)? Decision: add helper now, enforce in follow-up tenant-scoped S3 change to avoid changing current upload paths (`/{tenant_id}/...` already tenant-prefixed in `file-upload` spec).
