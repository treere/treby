## 1. Navigation — explicit Home / Dashboard

- [x] 1.1 Team app header: add explicit **Home** link as first item in `lib/treby_web/components/layouts.ex` `.app` desktop nav (`xl:flex`) and mobile drawer; `navigate` to `/:tenant_slug/app` (fallback `~p"/app"`), add `id="nav-home"`, `data-nav="/app"`, `aria-current="page"` when active, pill active style, 44px touch targets, `gettext("Home")`.
- [x] 1.2 Candidate portal header: add explicit **Dashboard** link as first item in `.candidate_portal` desktop (`sm:flex`) and mobile drawer; `navigate` to `/:tenant_slug/portal`, same active pill/`aria-current`, `gettext("Dashboard")`, keep brand link as duplicate affordance.
- [x] 1.3 Highlighting: update active-link logic so Home/Dashboard highlight correctly on their routes; verify no regression for Jobs/Candidates/Interviews/Analytics/Assistant and portal Messages/Schedule/Settings.

## 2. Candidate portal dashboard — summary and enriched cards

- [x] 2.1 `lib/treby_web/live/candidate_portal_live/index.ex`: compute summary stats on mount — `total_applications` (count), `unread_count` (conversations where last message `sender_type=="recruiter"`), `pending_actions_count` (per-app `candidate_pending_action` non-nil) — and refresh on `{:conversation_updated, _}`; assign as `@stats`.
- [x] 2.2 `lib/treby_web/live/candidate_portal_live/index.ex` render: add summary strip (3 stats) above applications list + per-card enrichments — company name/logo (from `@current_tenant`), location/type badges when job carries them, unread dot/badge + one-line message preview, applied date; add small company info block (logo, name, description when `company_description` present, "Need help? ..." only when `support_email`/`contact_email` present).
- [x] 2.3 Verify tenant scoping: all counts/queries filter by `(tenant_id, candidate_id)`; tenant-slug mismatch redirect unchanged; test `mix test test/treby_web/live/candidate_portal_live_test.exs` (or nearest portal test).

## 3. Settings — single-page scroll + auto-scroll to content

- [x] 3.1 `lib/treby_web/components/settings_layout.ex`: remove `lg:max-h-[calc(100vh-6rem)] lg:overflow-y-auto` from sidebar wrapper; keep `lg:sticky lg:top-20` only; add `id="settings-main"` to main pane `<div class="flex-1 ...">`; add colocated hook `script :type={Phoenix.LiveView.ColocatedHook} name=".SettingsScroll"` that on `mounted`/`updated` when `active_key != nil` (passed via data attribute) calls `getElementById("settings-main")?.scrollIntoView({behavior:"smooth", block:"start"})`; inert when `active_key==nil`.
- [x] 3.2 Verify manually: Settings hub has single scrollbar at 1280px; child pages (`/settings/pipeline`, `/settings/team`, `/messages-queue`, etc.) single scrollbar; clicking sidebar on mobile and on desktop when scrolled down brings `#settings-main` into view; hub (`/app/settings`) does not auto-scroll.

## 4. Tests and validation

- [x] 4.1 Add/update LiveView/unit tests: team nav shows Home first (desktop+drawer) and highlights on `/app`; portal nav shows Dashboard first (desktop+drawer) and highlights on `/portal`; portal dashboard shows summary strip + company/unread per card; settings single-scroll (one scrollbar, no inner overflow) and auto-scroll hook inert on hub / active on child.
- [x] 4.2 Run targeted tests: `mix test test/treby_web/live/settings_live_test.exs test/treby_web/live/candidate_portal_live_test.exs` (or equivalent paths) and fix failures.

## 5. Specs + docs

- [x] 5.1 Update main specs at `openspec/specs/app-navigation/spec.md`, `openspec/specs/candidate-portal-dashboard/spec.md`, `openspec/specs/settings-navigation/spec.md` to match delta specs in this change (plus Purpose/Requirements/Scenario `WHEN`/`THEN` with 4-hash scenarios).
- [x] 5.2 Sync user manual if navigation/screenshots show the changed areas: update `site/features/*.md` + `site/features/index.md` and sidebar in `site/.vitepress/config.ts` (English only, no file paths or module names), then regenerate screenshots: `node scripts/screenshots.mjs`.
- [x] 5.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
