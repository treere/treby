## Context

List views (`candidates_live/index.ex`, `jobs_live/index.ex`, pipeline board) call `list_candidates/2`, `list_jobs/1`, `list_applications_for_job/1` — all unbounded `Repo.all()` into plain `@candidates`/`@jobs` assigns (no streams). Analytics `pipeline_counts_per_stage(nil)` loops one `count` per stage; `time_in_stage_metrics/2` loads all stage-change logs ever. Searches are `%term%` `ilike` with no index support. Postgres 18 (official image) ships `pg_trgm` as a contrib module needing only `CREATE EXTENSION`. No migration in the repo uses `execute` or concurrent indexes yet.

Stakeholders: staff users on large workspaces (page load), self-hosters (migration safety on existing data).

## Goals / Non-Goals

**Goals:**
- Bounded queries + bounded DOM for the three main listings with deep-linkable pages.
- Indexed `ilike` search and single-query stage counts with identical results.
- Zero-downtime migrations safe to run on populated databases.

**Non-Goals:**
- No keyset/cursor pagination (offset is fine at this scale; see Decision 1).
- No full-text/ranking search (trigram `ilike` only; same result semantics).
- No infinite scroll (explicit pager per design system).
- No PgBouncer `prepare: :unnamed` switch and no S3 retry work (separate 🟢 items, left in the file).

## Decisions

**Decision 1: Offset pagination with `{entries, total, total_pages}` tuple**
- Helper `paginate(query, page, page_size)` (in `Candidates.Queries`, reused via import by Jobs/Applications or duplicated 10-line impl per context? — single impl in Queries + delegate) applies `limit/offset` plus a `count` query excluding ordering. Defaults: page 1, size 25 (config `:treby, :default_page_size`), max 100. LiveViews parse `page` in `handle_params`, clamp to `[1, total_pages]`, and `push_patch` on pager clicks so back-button and filters compose.
- *Rationale:* Offset is simple, deep-linkable, and total counts feed the "Showing X–Y of Z" label users expect; tables here are staff-facing (hundreds–low-thousands rows), far below keyset territory.
- *Alternative:* keyset pagination — rejected, breaks page numbers and deep links for negligible gain at this scale.

**Decision 2: `DesignSystem.Pagination` as controlled component + story**
- Props: `page`, `total_pages`, `total_count`, `page_size`, `patch` base path or `on_page` event name, `id="pagination"`. Renders Prev/Next buttons (disabled states), windowed page numbers (1 … current±2 … last), result count text, `aria-label`/`aria-current`, full `dark:` classes, `orange-600` active page per CTA token. Story covers: first/middle/last page, single page (hidden), 0 results.
- *Rationale:* Matches existing DS component conventions (`badge.ex` shape: `attr` + `@doc ~S'''` + `~H`); controlled design keeps LiveViews owning URL state.
- *Alternative:* client-side pager over full dataset — rejected, defeats the purpose.

**Decision 3: Concurrent GIN trigram indexes**
- Migration 1: `execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", ""` (no downgrade) + `create index(..., using: :gin, concurrently: true)` on `candidates.name`, `candidates.email`, `jobs.title` with `opclass gin_trgm_ops`? Ecto: `create index(:candidates, ["name"], using: :gin)` — trigram opclass requires `... USING gin (name gin_trgm_ops)`; Ecto supports `using: "gin (name gin_trgm_ops)"`? Ecto's `using` accepts fragment-ish string. Safer: `execute "CREATE INDEX CONCURRENTLY ... USING gin (col gin_trgm_ops)", "DROP INDEX ..."` with explicit names (`candidates_name_trgm_idx`, etc.). Module uses `@disable_ddl_transaction!`.
- *Rationale:* `CONCURRENTLY` avoids write locks on populated tables; explicit `execute` is clearer than fighting Ecto's `using:` for opclasses, and matches the "no execute precedent" gap with a documented pattern.
- *Alternative:* default btree indexes — rejected, useless for `%term%` leading-wildcard `ilike`.

**Decision 4: Single-query stage counts + 90-day time-in-stage window**
- `pipeline_counts_per_stage(nil)`: one query `group_by pipeline_stage_id` → counts map → map over stages (identical output shape; property test global-vs-grouped parity on seed data). `time_in_stage_metrics/2`: filter `activity_logs.inserted_at >= 90.days.ago` + composite index `(entity_type, entity_id, inserted_at)`. Window constant `90` in module attribute, documented in analytics UI label ("last 90 days").
- *Rationale:* Removes N+1 and unbounded log scans; 90-day window matches hiring-cycle relevance and keeps the in-memory chunking cheap.
- *Alternative:* SQL window-function rewrite — rejected, larger blast radius for same practical gain.

**Decision 5: Partial active-candidate index**
- `create index(:candidates, [:tenant_id], where: "merged_into_id IS NULL", name: :candidates_active_tenant_idx)` (plain btree, non-concurrent is fine — small, fast — but use concurrently anyway for uniformity? Non-concurrent keeps the migration transactional and simple; table locks for a tiny index build are milliseconds. Decision: plain `create index` in the same migration as the activity-log index.)

## Risks / Trade-offs

- **`CREATE EXTENSION` needs superuser/rp DB owner** → Mitigation: self-hosted Postgres runs as superuser by default (compose `postgres` user); document fallback (ask DBA to pre-create) in migration comment.
- **Offset deep pages slow on huge tables** → Mitigation: max page_size 100 + total_pages clamp; acceptable per Decision 1; revisit with keyset if a tenant exceeds ~50k rows.
- **Pager + LiveView filter interplay** → Mitigation: page resets to 1 on any filter/search change; `handle_params` is the single source of truth; tests cover filter→page-reset and back-button.
- **90-day window changes analytics numbers** → Mitigation: explicit spec delta + UI label; all-time export remains available via existing CSV flows (out of scope).

## Migration Plan

1. Migration A (extensions + GIN, `@disable_ddl_transaction!`, concurrent) — deployable alone, backward compatible (planner may ignore indexes until stats update; run `ANALYZE` note in output).
2. Migration B (activity-log composite + candidates partial, transactional) — same release or separate; both additive, rollback = drop indexes.
3. Ship `paginate` + context wiring behind identical defaults (page 1 = previous full-list behavior for small datasets? No — page 1 returns first 25; UI shows pager; tests assert).
4. Ship DS Pagination + stories, then LiveView wiring per page (candidates → jobs → pipeline board).
5. Rollback: revert commits; `mix ecto.rollback --step 2`; no data change involved.

## Open Questions

- Default page size 25 vs 50 for the pipeline board (denser Kanban)? Proposed: 25 everywhere for consistency; board columns paginate per-column? Decision: pipeline board paginates the whole application list (25), columns render from the page slice — confirm during implementation if column slicing looks wrong, fallback to per-column caps.
