## 1. Config & Shared Helpers

- [x] 1.1 Extract S3 bucket to runtime config — add `config :treby, :s3_bucket, "treby-uploads"` in `config/config.exs` and override in `config/runtime.exs` via `Env.env("S3_BUCKET") || Env.env("TREBY_S3_BUCKET")`; verify `mix test` still passes with default.
- [x] 1.2 Create `Treby.Helpers.Map` (`lib/treby/helpers/map.ex`) with `stringify_keys/1` and add unit test; verify `grep -R "defp stringify_keys"` leaves only helper.

## 2. Pipeline — Stages Submodule

- [x] 2.1 Create `Treby.Pipeline.Stages` (`lib/treby/pipeline/stages.ex`) moving pipeline CRUD (`list_pipelines`, `get_pipeline!`, `create/update/delete_pipeline`, `set_default_pipeline`, `default_pipeline_id`, `count_active_jobs`, `count_pipeline_stages`) + stage CRUD (`list_pipeline_stages`, `create/update/delete_pipeline_stage`, `reassign_and_delete_stage`, `delete_pipeline_with_reassignment`) + role assignments (examiners/reviewers/advancers + `user_is_advancer?`) from `lib/treby/pipeline/pipeline.ex:1-500`; keep `Treby.Pipeline` delegating via `defdelegate`.
- [x] 2.2 Create `Treby.Pipeline.Stages` template helpers (`list_templates`, `clone_pipeline`, `clone_template_to_pipeline`, `duplicate_pipeline`, `job_effective_pipeline_id`, `pipeline_shared?`, `detach_job_pipeline` with `remap_job_applications`) with transaction safety; verify `mix test test/treby/pipeline_test.exs` passes.
- [x] 2.3 Verify compilation with `mix compile --warnings-as-errors` and that all aliases `Treby.Pipeline` still resolve via facade.

## 3. Pipeline — Applications Submodule

- [x] 3.1 Create `Treby.Pipeline.Applications` (`lib/treby/pipeline/applications.ex`) moving application listing (`list_applications_for_job`, `list_applications_for_candidate`, `list_applications_by_stage`, `candidate_application_counts`, `other_positions_text`, `get_application!`), `create_application` (with `ensure_anagrafica`, `set_duplicate_flag`, `build_anagrafica` via `Helpers.Map`), `recompute_duplicate_flags`, and review helpers (`mark_reviewed`, `mark_unreviewed`, `toggle_reviewed`).
- [x] 3.2 Move `move_application/3` (with PubSub broadcast, `Activities.log_event`, `Audit.log_event`, `skip_notification` handling) and `subscribe_to_pipeline/1` plus progress helpers (`current_state`, `ready_to_advance?`, `interview_completed?`, `all_scorecards_completed?`) into `Applications`; ensure `Treby.Pipeline` delegates and `Treby.Candidates.Merge` calls `recompute_duplicate_flags` via facade.
- [x] 3.3 Replace local `stringify_keys` in applications path with `Treby.Helpers.Map.stringify_keys/1`; verify `mix test test/treby/pipeline/applications_test.exs` (or existing pipeline tests) green.

## 4. Pipeline — Analytics Deduplication

- [x] 4.1 Create `Treby.Pipeline.Analytics` (`lib/treby/pipeline/analytics.ex`) moving all analytics (`pipeline_counts_per_stage/1+2`, `average_time_to_hire/1+2`, `stage_conversion_rates/1+2`, `time_in_stage_metrics/2`, `source_breakdown/1+2`, helpers `per_pipeline_conversion_rates`, `all_pipelines_conversion_rates`, `do_time_in_stage_metrics`) and introduce private `scoped_pipeline_ids/1` + `scoped_application_query/1` so `(.../2 tenant_id, pipeline_id)` delegates to single implementation; `Treby.Pipeline` delegates.
- [x] 4.2 Verify tenant scoping parity — add test asserting `pipeline_counts_per_stage(nil)` counts equal `pipeline_counts_per_stage(tenant_id, nil)` when tenant owns all pipelines; run `mix test test/treby/pipeline_test.exs`.

## 5. Candidates — Queries & Merge Split

- [x] 5.1 Create `Treby.Candidates.Queries` (`lib/treby/candidates/queries.ex`) with `base_active_query/1`, `apply_search/2`, `apply_job_filter/2`, `apply_stage_filter/2` (single top-level `import Ecto.Query`, no inline imports); update `Treby.Candidates.list_candidates/2` to delegate; remove `import Ecto.Query` inside `candidates.ex:42,56`.
- [x] 5.2 Create `Treby.Candidates.Merge` (`lib/treby/candidates/merge.ex`) moving `validate_merge_targets`, `do_merge`, `reassign_to_primary`, `reassign_candidate_activities`, `merge_candidates/3`, `undo_merge/2`, `restore_owner`, `parse_mapping_ids`, plus `dismiss_merge_group`, `list_dismissed_group_keys`, `list_suggestion_groups`, `auto_merge_exact_email`; use `Helpers.Map.stringify_keys`; `Treby.Candidates` delegates.
- [x] 5.3 Verify no duplicate helpers remain — `grep -R "stringify_keys\|apply_job_filter\|apply_stage_filter" lib/treby --include="*.ex"` shows single definitions; `mix compile --warnings-as-errors` clean.

## 6. Uploads — Runtime Bucket & Tenant Key Helper

- [x] 6.1 Update `Treby.Uploads` (`lib/treby/uploads.ex`) to read bucket via `Application.get_env(:treby, :s3_bucket, "treby-uploads")` (runtime) in `upload_file/3`, `get_presigned_url/2`, `delete_file/1`, `ensure_bucket_exists!/0`; add `bucket/0` and `scoped_key/2` (validates `"#{tenant_id}/"` prefix else raises); add unit test for env override and `scoped_key` validation.
- [x] 6.2 Run `mix test test/treby/uploads_test.exs` (or relevant) and manual `Treby.Uploads.bucket()` check with `S3_BUCKET` override.

## 7. Tests & Regression

- [x] 7.1 Run full suite `mix test` and fix any facade delegation misses; ensure 522+ tests green and no warnings.
- [x] 7.2 Add regression tests: (a) analytics tenant vs global parity, (b) `Treby.Uploads.scoped_key` raises on cross-tenant key, (c) `Helpers.Map.stringify_keys` idempotent.

## 8. Specs & Docs Sync

- [x] 8.1 Sync main specs — copy delta specs from `openspec/changes/refactor-architecture-quality/specs/**` to `openspec/specs/pipeline/spec.md`, `openspec/specs/candidate-management/spec.md`, `openspec/specs/file-upload/spec.md` (run `openspec sync` or manual copy) and ensure `openspec validate --strict` passes.
- [x] 8.2 Verify user manual unchanged — confirm `site/` requires no update per `AGENTS.md` (no file paths/module names in user docs); run `cd site && npm run build` smoke check and `node scripts/screenshots.mjs` no-op verification.
- [x] 8.3 Run `mix precommit` and `openspec validate --strict` and fix all issues (format, credo, sobelow, translations, design-system guard).
