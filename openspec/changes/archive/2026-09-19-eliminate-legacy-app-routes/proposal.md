## Why

Authenticated app links still use legacy `/app/*` paths without tenant slug (e.g. `/app/jobs`, `/app/candidates`) even when a tenant is present at `/:tenant_slug/app`. They work via `live_session :legacy_*` fallback but violate `multi-tenancy` SHALL (all authenticated pages under `/:tenant_slug/app/*`) and `workspace-switching` deep-link preservation. Bookmarks and copied URLs lose workspace context, break multi-tenant isolation, and cause 404/redirect to login when opened without session. Reports `R5`/`R6` flagged this as medium/low but spec-violating.

## What Changes

- **BREAKING**: Remove `live_session :legacy_default` and `:legacy_admin` from `lib/treby_web/router.ex` (`scope "/app"` with LiveViews). Keep only `get "/*path", LegacyAppController, :redirect_legacy` which redirects `/app/*` to `/:tenant_slug/app/*` or `/choose-tenant`.
- Replace all `~p"/app/..."` hrefs/navigates/push_navigates in `lib/treby_web/*` (layouts, header/sidebar, 14 settings lives, jobs/candidates/pipeline/import/comparison/schedule/notifications/analytics) with tenant-scoped `if @current_tenant, do: "/#{@current_tenant.slug}/app/..." else: ~p"/app/..."` (fallback only when no tenant).
- Update pagination helpers and resume/redirect helpers to use tenant slug.
- Update `test/` suites that hit `~p"/app/..."` to use tenant slug paths with `setup_tenant` and `init_test_session(%{"user_id" => user.id})`.
- No new dependencies, no migration.

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `multi-tenancy`: Enforce `URL-scoped workspace routing` — `Authenticated navigation preserves workspace` (all links include current tenant slug) and `Legacy /app redirect` (now sole handler for `/app/*`).
- `workspace-switching`: `Deep link preserves workspace` — links shared as `/:tenant_slug/app/jobs/:id` remain workspace-scoped.
- `app-navigation`: `Home` and primary nav links point to `/:tenant_slug/app` when tenant present.

## Impact

- Affected code: `lib/treby_web/router.ex`, `lib/treby_web/components/layouts*`, `lib/treby_web/live/**/*` (jobs, candidates, pipeline, settings 14 lives, import, comparison, schedule, etc.), `lib/treby_web/components/design_system/pagination.ex`, `lib/treby_web/controllers/resume_controller.ex`.
- Tests: `test/treby_web/live/*` and `test/treby_web/integration/*` that use legacy paths.
- No DB migration.
- Breaking for external bookmarks to `/app/*` without slug — they now 302 to tenant-scoped or `/choose-tenant` instead of rendering.
