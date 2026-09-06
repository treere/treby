## 1. Design-system theme-aware helpers

- [x] 1.1 Update `variant_classes/1` in `lib/treby_web/components/design_system.ex` to add `dark:` overrides for `secondary` (`dark:bg-zinc-800 dark:text-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-700`), `ghost` (`dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-zinc-100`), and `outline` (`dark:bg-zinc-800 dark:text-zinc-200 dark:border-zinc-600 dark:hover:bg-zinc-700`)
- [x] 1.2 Update `badge_classes/1` in same file to add `dark:` overrides for all variants: `default` → `dark:bg-zinc-700 dark:text-zinc-200 dark:border-zinc-600`, `success` → `dark:bg-emerald-950 dark:text-emerald-200 dark:border-emerald-800`, `warning` → `dark:bg-amber-950 dark:text-amber-200 dark:border-amber-800`, `danger` → `dark:bg-red-950 dark:text-red-200 dark:border-red-800`, `info` → `dark:bg-blue-950 dark:text-blue-200 dark:border-blue-800`
- [x] 1.3 Verify helpers compile and visually: `mix compile` and manual render of `<.button variant="ghost">` / `<.badge variant="default">` inside `bg-white dark:bg-zinc-800` shows ≥4.5:1 in dark (axe spot-check)

## 2. Public careers pages — contrast + i18n (exemplars)

- [x] 2.1 Fix `/careers` search input in `lib/treby_web/live/careers_live/global_index.ex` (and `lib/treby_web/live/careers_live/index.ex` for tenant board): replace bare `class="input flex-1"` with explicit theme-aware classes `bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400` (or wire through `<.input>`), so typed text and placeholder both meet contrast on `dark:bg-zinc-800`
- [x] 2.2 Fix `lib/treby_web/live/careers_live/show.ex` back navigation: change `&larr; Back to all positions` link from `class="text-primary hover:text-primary/80"` to `class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100"` (or `dark:text-orange-300` if keeping primary) and add `dark:` so it is ≥4.5:1 on `bg-zinc-50 dark:bg-zinc-800`; wrap string with `gettext("Back to all positions")`
- [x] 2.3 Fix `show.ex` ghost fallbacks on closed/not-found states: `View other positions` already via `<.button variant="ghost">` benefits from 1.1, but ensure the surrounding muted description `text-zinc-500 dark:text-zinc-400` is used (not inverted) and wrap `View other positions` hardcoded strings (lines 225, 237) with `gettext("View other positions")`
- [x] 2.4 Fix `show.ex` tenant description line `text-zinc-400 dark:text-zinc-500` → `text-zinc-500 dark:text-zinc-400` and wrap any remaining hardcoded headings (`"This position is no longer available"` / `"Position not found"` already use gettext — verify no bare English remains) — audit whole `show.ex` render for non-gettext user strings
- [x] 2.5 Wrap any remaining hardcoded strings in `show.ex` (e.g., back arrow label) with `gettext`, run `mix gettext.extract --merge`, add Italian translations in `priv/gettext/it/LC_MESSAGES/default.po` (`"Back to all positions"` → `"Torna a tutte le posizioni"`, `"View other positions"` → `"Vedi altre posizioni"`), and run `mix treby.check_translations` to confirm 0 missing

## 3. Muted-text, headings, and input sweep

- [x] 3.1 Grep `lib/treby_web` for `text-zinc-400 dark:text-zinc-500` and flip to `text-zinc-500 dark:text-zinc-400` (or `text-zinc-600 dark:text-zinc-400` where body copy needs it) — cover `lib/treby_web/live/careers_live/*`, `lib/treby_web/components/core_components.ex` table headers / muted captions, `lib/treby_web/components/design_system/*` (pattern empty_state, page_header), plus any `text-zinc-400` on `dark:bg-zinc-800` without dark override and `DashboardLive` weekly-stats/action rows
- [x] 3.2 Audit all `placeholder:text-zinc-` and raw `class="input"` usages (`lib/treby_web/live/careers_live/*`, `candidate_portal_live/*`, `pipeline_live/*`, `candidates_live/*`, `settings_live/*`) and ensure each has `dark:placeholder:text-zinc-400` / `dark:text-zinc-100` with `dark:bg-zinc-800` `dark:border-zinc-700`; also fix `placeholder-base-content/50` in `session_html/new.html.heex` + `password_reset_html/*` to `placeholder:text-zinc-400 dark:placeholder:text-zinc-400`
- [x] 3.3 Fix dashboard headings at `lib/treby_web/live/dashboard_live.ex` (`h2` titles "My Actions"/"Le mie azioni", "Upcoming Interviews", "Stale Candidates", etc.) that have `text-lg font-semibold` without `dark:text-*`: add `text-zinc-900 dark:text-zinc-100` so they are legible inside `bg-white dark:bg-zinc-800` cards
- [x] 3.4 Fix `lib/treby_web/controllers/session_html/new.html.heex` "Forgot your password?" (and sibling `text-primary` auth links in `password_reset_html/*`, `registration_html/*`) to include `dark:text-orange-400` (or `dark:text-zinc-300`) hover override so ≥4.5:1 in dark mode
- [x] 3.5 Ensure `assets/css/app.css` custom `@custom-variant dark` block remains source of truth and no new hardcoded `gray-*` surfaces are introduced; adjust if axe reports token-level failures

## 4. Public header for unauthenticated/tenant-public pages

- [x] 4.1 Create `TrebyWeb.Layouts.public_header/1` component that renders homepage brand link (`Treby` → `~p"/"`) on the left and `theme_toggle` + `locale_switcher` on the right with contrast-compliant styling (`bg-white/80 dark:bg-zinc-900/80` etc.) — reuse `auth_toolbar` pattern
- [x] 4.2 Use `public_header` in `CareersLive.GlobalIndex` (`/careers`), `CareersLive.Index` (`/:tenant_slug/careers`), `CareersLive.Show` (`/:tenant_slug/careers/:job_id`), and `CareersLive.Apply` (`/:tenant_slug/careers/:job_id/apply`); pass `@locale`/`@tenant` as needed and verify header shows homepage + theme + language in all themes/locales
- [x] 4.3 Add homepage brand link to password pages: update `lib/treby_web/controllers/password_reset_html/new.html.heex` and `edit.html.heex` to render Treby logo → `/` alongside existing `Layouts.auth_toolbar` (top-left brand + top-right controls pattern), keeping `dark:text-*` contrast

## 5. Tests and guardrails

- [x] 5.1 Add/extend LiveView or component tests: assert `/careers` search input renders with `dark:placeholder` and `dark:text` classes; assert `CareersLive.Show` back link uses `gettext` and renders translated IT string when `Gettext.put_locale(TrebyWeb.Gettext, "it")`; assert `DashboardLive` headings include `dark:text-zinc-100`; assert `SessionHTML` forgot-password link includes `dark:text-*`; assert careers/password pages render `public_header` homepage link and theme+language controls
- [x] 5.2 Add axe-based verification: `node scripts/screenshots.mjs --axe` captures `/careers`, `/:tenant_slug/careers/:job_id` (use seeded tenant `acme` and job `8dec86b3-7584-47f0-b9f6-7af6625a55da` or seeded equivalent), `/login` (forgot password link), `/:tenant_slug/app` (dashboard titles "Le mie azioni"), and `/reset-password` in both light and dark (`data-theme="dark"`) and asserts zero serious/critical `color-contrast` violations; document the command in `AGENTS.md` guardrail line if not present

## 6. Specs and docs sync

- [x] 6.1 Sync deltas to main specs: `openspec/specs/dark-theme-contrast`, `openspec/specs/dark-mode`, `openspec/specs/design-system`, `openspec/specs/i18n`, `openspec/specs/dashboard`, `openspec/specs/authentication`, `openspec/specs/career-page`, `openspec/specs/public-job-board` — ensure each spec's Purpose/Requirements/Scenarios reflect this change (run `openspec validate --strict` will catch mismatches)
- [x] 6.2 If this change adds user-facing docs, update `site/features/*.md` and `site/.vitepress/config.ts` + `site/features/index.md`; otherwise confirm no site update needed beyond guardrail note — regenerate screenshots with `node scripts/screenshots.mjs` and verify no light-theme regression

## 7. Validation

- [x] 7.1 Run `mix precommit` and `openspec validate --strict` and fix all reported issues
