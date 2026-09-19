## 1. Router

- [x] 1.1 Remove `live_session :legacy_default` and `:legacy_admin` blocks from `lib/treby_web/router.ex` `scope "/app"`; keep only `get "/*path", LegacyAppController, :redirect_legacy` as first route in that scope
- [x] 1.2 Verify `LegacyAppController.redirect_legacy` preserves path+query and redirects to `/:tenant_slug/app/*` (sole membership), `/choose-tenant` (multiple), or `/login` (no session) with flash

## 2. Navigation and Layouts

- [x] 2.1 Update `lib/treby_web/components/layouts.ex` (desktop + mobile nav, header, drawer) to use tenant-scoped hrefs: `if @current_tenant, do: "/#{@current_tenant.slug}/app/..." else: ~p"/app/..."` for Home, Jobs, Candidates, Interviews, Analytics, Assistant, brand logo, and data-nav attributes
- [x] 2.2 Update `lib/treby_web/components/design_system/pagination.ex` to accept tenant slug or use `~p"/app/candidates"` fallback only when no tenant

## 3. LiveViews — Primary Domains

- [x] 3.1 Update `lib/treby_web/live/jobs_live/*` (index, show, new, analytics) - all `~p"/app/jobs..."` navigates/push_navigates/breadcrumbs to tenant-scoped
- [x] 3.2 Update `lib/treby_web/live/candidates_live/*` (index, show, merge) and `comparison_live`, `pipeline_live`, `schedule_live`, `import_live`, `interviews_live`, `messages_queue_live`, `notifications_live`, `error_live` to tenant-scoped
- [x] 3.3 Update pagination and resume/return helpers (`safe_return_path`, `merged_redirect`) in `candidates_live/show.ex` to tenant-scoped

## 4. Settings Lives

- [x] 4.1 Update all 14 settings lives (`lib/treby_web/live/settings_live/*.ex` - pipeline, pipeline_stages, fields, team, webhooks, branding, company_availability, scorecards, emails, notifications, audit_log, data_privacy, calendar, availability, language) — `Back to Settings` and internal links to tenant-scoped
- [x] 4.2 Update `lib/treby_web/live/dashboard_live.ex` and `lib/treby_web/controllers/resume_controller.ex` links to tenant-scoped

## 5. Tests

- [x] 5.1 Update `test/treby_web/live/*` and `test/treby_web/integration/*` that drive `~p"/app/..."` to use `"/#{tenant.slug}/app/..."` with `setup_tenant` and `init_test_session(%{"user_id" => user.id})`; keep one dedicated test for legacy redirect (`GET /app/jobs` → 302)
- [x] 5.2 Run `mix test` for affected suites and fix failures

## 6. Specs and Docs

- [x] 6.1 Sync delta specs to main specs: `openspec/specs/multi-tenancy/spec.md`, `openspec/specs/workspace-switching/spec.md`, `openspec/specs/app-navigation/spec.md` via `openspec sync` or manual edit
- [x] 6.2 Update `site/features/*.md` and `site/.vitepress/config.ts` if navigation labels change; regenerate screenshots with `node scripts/screenshots.mjs` and verify light/dark

## 7. Verification

- [x] 7.1 Run `mix precommit` and `openspec validate --strict` and fix issues
