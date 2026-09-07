## 1. Migrations

- [x] 1.1 Create pg_trgm + GIN migration — run `mix ecto.gen.migration enable_pg_trgm_and_search_indexes` with `@disable_ddl_transaction!`, `CREATE EXTENSION IF NOT EXISTS pg_trgm`, and `CREATE INDEX CONCURRENTLY ... USING gin (col gin_trgm_ops)` for `candidates.name`, `candidates.email`, `jobs.title`; verify `mix ecto.migrate` + `mix ecto.rollback --step 1` + `mix ecto.migrate` round-trip on dev.
- [x] 1.2 Create supporting-index migration — run `mix ecto.gen.migration add_analytics_and_active_indexes` adding composite index on `activity_log(entity_type, entity_id, inserted_at)` and partial index `candidates(tenant_id) WHERE merged_into_id IS NULL`; verify migrate/rollback round-trip.

## 2. Context — Pagination & Single-Query Counts

- [x] 2.1 Add `paginate/3` helper — implement `Candidates.Queries.paginate(query, page, page_size)` returning `{entries, total_count, total_pages}` (page clamp, size default 25 via `config :treby, :default_page_size`, max 100) and wire `page:`/`page_size:` opts into `list_candidates/2`, `Jobs.list_jobs/1`, `Applications.list_applications_for_job/1`; verify `mix test test/treby/candidates_test.exs test/treby/jobs_test.exs` green.
- [x] 2.2 Rewrite global stage counts as single grouped query — replace the per-stage `count` loop in `Analytics.pipeline_counts_per_stage(nil)` with `group_by pipeline_stage_id` + in-memory mapping (same shape as `pipeline_counts_per_stage_for_job/1`); add parity test old-vs-new on seed data; run `mix test test/treby/pipeline_test.exs`.
- [x] 2.3 Bound time-in-stage to 90 days — filter `activity_logs.inserted_at >= 90 days ago` in `Analytics.do_time_in_stage_metrics` path (module attribute window) and label the analytics UI "last 90 days"; verify `mix test test/treby/pipeline_test.exs` green.

## 3. Design System — Pagination Component

- [x] 3.1 Create `DesignSystem.Pagination` (`lib/treby_web/components/design_system/pagination.ex`) with `page`, `total_pages`, `total_count`, `page_size`, `id="pagination"`, Prev/Next + windowed numbers + result count, ARIA + `dark:` + `orange-600` active token; verify `mix compile --warnings-as-errors`.
- [x] 3.2 Add Storybook story (`storybook/components/pagination.story.exs`) covering first/middle/last/single-page/empty states; verify story renders in dev storybook.

## 4. LiveView/UI

- [x] 4.1 Paginate candidates page — `candidates_live/index.ex`: `handle_params` reads `page`, resets to 1 on filter/search change, `push_patch` on pager events, render `<.pagination>`; verify pager `has_element?("#pagination")` in LiveView test.
- [x] 4.2 Paginate jobs page — same wiring in `jobs_live/index.ex`; verify LiveView test.
- [x] 4.3 Paginate pipeline board applications — wire paging into `pipeline_live/index.ex` per-job application list; verify LiveView test.

## 5. Tests

- [x] 5.1 Add pagination regression tests — page 2 returns distinct rows, out-of-range page clamps, filter resets to page 1, `EXPLAIN` uses trigram index for `%term%` search; run `mix test` full suite green with zero warnings.

## 6. Specs & Docs Sync

- [x] 6.1 Sync main specs — merge delta specs from `openspec/changes/perf-pagination-trgm/specs/**` into `openspec/specs/{candidate-management,job-management,applications,analytics,candidate-search,job-search,design-system,storybook-preview}/spec.md`, update the matching `site/features/*.md` pages (user-visible paging + 90-day analytics label) and regenerate screenshots with `node scripts/screenshots.mjs`; ensure `openspec validate --strict` passes.
- [x] 6.2 Run `mix precommit` and `openspec validate --strict` and fix all issues (format, credo, sobelow, translations, design-system guard).
