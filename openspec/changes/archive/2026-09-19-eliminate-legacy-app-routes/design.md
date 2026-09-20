## Context

`lib/treby_web/router.ex` currently defines two parallel authenticated scopes:

- `scope "/:tenant_slug/app"` with `live_session :default` and `:admin` (correct, slug-scoped, `RequireMembership` + `RequireRole`).
- `scope "/app"` with `live_session :legacy_default` and `:legacy_admin` (session-based fallback, kept for one release per comment). It duplicates every LiveView route and is still the target of most `~p"/app/..."` hrefs in `lib/treby_web/live/**/*` and `lib/treby_web/components/layouts.ex`.

`LegacyAppController.redirect_legacy` already exists at `get "/*path", LegacyAppController, :redirect_legacy` inside the legacy scope, but it is shadowed by the live routes above it (lives match first). Reports `R5`/`R6` show that navigating to `/acme/app` still renders header links with `href="/app/jobs"`; copying that URL to a fresh browser loses workspace and lands on login or wrong tenant.

Stakeholders: all authenticated users (single- and multi-tenant), tests that currently drive `~p"/app/..."` via `init_test_session(%{"user_id" => id})` without slug.

Constraints: tenant isolation via `tenant_id`; `current_tenant`/`current_membership` assigned in `RequireMembership` on_mount; LiveView `~p` verified routes require compile-time literals, so tenant slug must be interpolated via string `"/#{@current_tenant.slug}/app/..."`.

## Goals / Non-Goals

**Goals:**
- All authenticated hrefs/navigates/push_navigates include current tenant slug when `@current_tenant` present, falling back to `~p"/app/..."` only when no tenant (e.g. `/choose-tenant` edge).
- `GET /app/*` never renders LiveView; it 302 to `/:tenant_slug/app/*` (sole membership) or `/choose-tenant` (multiple) or `/login` (no session), preserving deep link path and query.
- Update tests to drive slug-scoped paths.

**Non-Goals:**
- Changing public career pages (`/:tenant_slug/careers`) or candidate portal (`/:tenant_slug/portal/*`) routing.
- Adding new DB columns or migrations.
- Removing `Tenant` slug generation or picker flow.

## Decisions

**Decision 1: Remove `live_session :legacy_*` lives, keep only redirect.**
- *Choice*: Delete the two `live_session` blocks under `scope "/app"`; keep single `get "/*path", LegacyAppController, :redirect_legacy` at top of that scope (before any live). `LegacyAppController` resolves `user_id` from session, lists memberships, and redirects: 0 → `/login`, 1 → `/#{tenant.slug}/app/#{path}`, N → `/choose-tenant` (with flash) or to stored `return_to`.
- *Rationale*: Eliminates duplicate route table and makes legacy a pure compatibility shim. Matches `multi-tenancy` spec `Legacy /app redirect`.
- *Alternative*: Keep lives and fix hrefs only — rejected: leaves ambiguous routing and doubles route maintenance.

**Decision 2: Tenant-scoped href helper pattern, no new abstraction.**
- *Choice*: Inline `if @current_tenant, do: "/#{@current_tenant.slug}/app/..." else: ~p"/app/..."` at each call site (layouts, header, sidebar, breadcrumb, pagination, controller redirects). No new `Routes` helper; keeps grep-able and follows existing pattern in `lib/treby_web/live/jobs_live/new.ex:82`.
- *Rationale*: Shortest diff, no new indirection, explicit fallback for nil tenant (e.g. `/app/settings` when not yet in workspace). A shared helper would save repetition but adds indirection for ~20 sites — not warranted.
- *Alternative*: Introduce `TrebyWeb.Helpers.routes_for_tenant/2` — rejected: over-engineering for a one-time migration.

**Decision 3: Preserve `~p` for slug-absent fallback only.**
- *Choice*: Keep `~p"/app/..."` only inside the `else` branch or in unauthenticated contexts and tests that explicitly need legacy redirect coverage (one test for redirect itself).
- *Rationale*: Verified routes remain useful for fallback, but primary path becomes string interpolation with runtime slug.

## Risks / Trade-offs

- [Risk] External bookmarks to `/app/jobs/:id` will now redirect instead of rendering directly → Mitigation: `LegacyAppController` preserves path+query, so bookmark still lands on correct `/:slug/app/jobs/:id` after one 302; document in release notes.
- [Risk] 30+ tests using `~p"/app/..."` will fail until updated to slug-scoped → Mitigation: batch update tests in same change; keep one dedicated legacy-redirect test to verify shim.
- [Risk] `push_navigate` with interpolated string loses compile-time verified route check → Mitigation: string is `"/#{slug}/app/..."` which matches `/:tenant_slug/app/*` scope; router will raise 404 if typo, caught by tests. Acceptable trade-off vs `~p` literal limitation with dynamic slug.

## Migration Plan

1. Land router change (remove legacy lives) behind same deploy; no migration.
2. Deploy; `mix precommit` must be green (compile --warnings-as-errors, credo, tests).
3. Rollback: revert router to restore lives if redirect misbehaves — no data change.

## Open Questions

- None. Legacy window ("one release") has elapsed; reports confirm breakage is user-visible now.
