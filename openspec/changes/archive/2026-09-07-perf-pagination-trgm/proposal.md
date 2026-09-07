## Why

Treby loads entire tables into memory on every list view: `Candidates.Queries.list_candidates/2`, `Jobs.list_jobs/1`, and `Applications.list_applications_for_job/1` all end in unbounded `Repo.all()` rendered into plain assigns, and `Analytics.pipeline_counts_per_stage/1` fires one `count` query per stage (N+1). Past ~1k records these pages degrade sharply (memory, TTFB, DOM size). At the same time every search is a leading-wildcard `ilike` with no trigram index, forcing sequential scans. This change makes lists bounded and searches indexed before scale hurts.

## What Changes

- Add server-side pagination (`page`/`page_size`, default 25, max 100) to candidate, job, and per-job application listings: new `paginate/3` helper returning `{entries, total_count, total_pages}`; LiveViews read `page` from URL params (`handle_params`), re-query on `paginate` events, and render a new `DesignSystem.Pagination` component (Prev/Next + compact page numbers + result count, `id="pagination"`, full `dark:` + a11y support).
- Add `DesignSystem.Pagination` (`lib/treby_web/components/design_system/pagination.ex`) + Storybook story (`storybook/components/pagination.story.exs`) following the existing component/story conventions.
- Add migration enabling `pg_trgm` and creating GIN trigram indexes (concurrently, `disable_ddl_transaction!`) on `candidates.name`, `candidates.email`, and `jobs.title`; rewrite `pipeline_counts_per_stage/1` (global) as a single `group_by pipeline_stage_id` query with in-memory mapping (same pattern as `pipeline_counts_per_stage_for_job/1`).
- Bound `Analytics.time_in_stage_metrics/2` to the last 90 days and add composite index on `activity_logs(entity_type, entity_id, inserted_at)`.
- Add partial index `candidates(tenant_id) WHERE merged_into_id IS NULL` for the active-candidate filter used by every listing.

## Capabilities

### New Capabilities
- _None_ — pagination reuses existing list capabilities; the Pagination component extends the existing design system.

### Modified Capabilities
- `candidate-management`: Candidate listing SHALL be paginated (25/page default) instead of returning all rows; search/filter combine with pagination.
- `job-management`: Job listing SHALL be paginated (25/page default).
- `applications`: Per-job application listing SHALL be paginated (25/page default).
- `analytics`: Time-in-stage metrics SHALL cover the trailing 90 days (documented window, not all-time); stage counts SHALL return identical results via a single grouped query.
- `candidate-search`: Candidate search SHALL use trigram-indexed `ilike` (same semantics, indexed).
- `job-search`: Job search SHALL use trigram-indexed `ilike` (same semantics, indexed).
- `design-system`: Catalog SHALL include a `Pagination` component with prev/next, page numbers, result count, dark mode, and keyboard/ARIA support.
- `storybook-preview`: Storybook SHALL show the new `Pagination` component with its states.

## Impact

- **Modules:** `lib/treby/candidates/queries.ex` (`paginate`), `lib/treby/jobs/jobs.ex`, `lib/treby/pipeline/applications.ex`, `lib/treby/pipeline/analytics.ex`, `lib/treby_web/components/design_system/pagination.ex`, `storybook/components/pagination.story.exs`, `lib/treby_web/live/candidates_live/index.ex`, `lib/treby_web/live/jobs_live/index.ex`, pipeline board LiveView (`pipeline_live/index.ex`) for per-job applications.
- **APIs:** List functions gain optional `page:`/`page_size:` opts (backward compatible defaults return page 1); LiveView URLs gain `?page=N` (deep-linkable, preserved across filter changes).
- **Dependencies:** None added.
- **Migrations:** Two (`mix ecto.gen.migration enable_pg_trgm_and_search_indexes`, `mix ecto.gen.migration add_candidates_active_index`): `CREATE EXTENSION IF NOT EXISTS pg_trgm`, GIN indexes with `concurrently: true` (+ `disable_ddl_transaction!`), composite activity-log index, partial candidates index.
- **Config:** Page-size default via `config :treby, :default_page_size, 25`.
- **Risks:** GIN index build time on large tables — mitigated with `concurrently: true` (no write lock); `handle_params` pagination must preserve existing filter params — covered by LiveView tests.
