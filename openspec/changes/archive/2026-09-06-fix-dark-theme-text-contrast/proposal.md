## Why

Several text elements become unreadable when dark theme is active — low-contrast combinations (e.g., `text-zinc-400`/`500` on `zinc-800`/`900` surfaces, light-on-light badges/buttons without dark variants, headings without `dark:text-*`, placeholder and muted copy) fail WCAG AA contrast and make the UI unusable in dark mode. Concrete reports: the search input on `/careers`, the "← Back to all positions" link on `/:tenant_slug/careers/:job_id` (e.g., `/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da`) with English/Italian mix when locale is Italian in dark mode (hardcoded English strings), the "Forgot your password?" link on `/login`, and section titles on `/acme/app` dashboard ("Le mie azioni" / "My Actions" and other `h2` headings, weekly-stats labels, action metadata) that disappear in dark mode (missing `dark:text-zinc-100` / inverted `text-zinc-400 dark:text-zinc-500`).

## What Changes

- Audit and fix all low-contrast text/background pairings in dark mode across app shells, auth pages, public careers pages, and design-system components so every text token meets WCAG AA (4.5:1 for normal text, 3:1 for large text) on its dark surface.
- Make `TrebyWeb.DesignSystem` variant and badge helpers theme-aware: add `dark:` overrides for `secondary`/`ghost`/`outline` button variants and all badge variants (`default`/`success`/`warning`/`danger`/`info`).
- Correct inverted muted-text mappings (e.g., `text-zinc-400 dark:text-zinc-500` → `text-zinc-500 dark:text-zinc-400` or `zinc-400` minimum on dark surfaces) and ensure `placeholder:text-zinc-400` remains legible in dark inputs — specifically the search field on `/careers`.
- Fix the "← Back to all positions" link and ghost fallbacks on `/:tenant_slug/careers/:job_id` for dark contrast (visible `dark:text-*` override, not low-contrast `text-primary` on `zinc-800`), and wrap all hardcoded English strings on that page with `gettext` so Italian locale never shows an English/Italian mix in any theme.
- Fix the "Forgot your password?" link on `/login` (and sibling `text-primary` auth links) to include a `dark:` override (e.g., `dark:text-orange-400` or `dark:text-zinc-300`) so it meets ≥4.5:1 on `bg-zinc-50 dark:bg-zinc-800` and does not disappear in dark mode.
- Fix dashboard headings at `/:tenant_slug/app` (e.g., "Le mie azioni" / "My Actions", "Upcoming Interviews", "Stale Candidates", "Pipeline Overview", "Recent Activity") and weekly-stats/action metadata that currently have no `dark:text-*` or inverted `text-zinc-400 dark:text-zinc-500`, by adding canonical `text-zinc-900 dark:text-zinc-100` for headings and `text-zinc-500 dark:text-zinc-400` for muted copy.
- Add a consistent public-page header to unauthenticated/tenant-public routes that are currently missing it: `/reset-password` (password), `/careers`, and `/:tenant_slug/careers` + `/:tenant_slug/careers/:job_id` (and apply). Each SHALL show a homepage link (Treby logo/name → `/`), plus the theme toggle and language switcher, so users can change theme/language and navigate home without using the browser back button. Auth pages already have `Layouts.auth_toolbar`; careers pages currently have none.
- Add/adjust `dark:` tokens in `assets/css/app.css` and component classes where contrast is computed from CSS variables or Tailwind dark variants.
- Add automated guardrails: `node scripts/screenshots.mjs --axe` must pass with zero serious/critical `color-contrast` violations in both light and dark theme captures; add a local grep/CI check that flags low-contrast muted pairings, headings without `dark:text-*` inside cards, and a `gettext` coverage check for the careers detail page.

## Capabilities

### New Capabilities
- `dark-theme-contrast`: Contrast guarantees and automated checks for dark theme readability (contrast ratios, token mappings, axe guardrail).

### Modified Capabilities
- `dark-mode`: Extend the existing legibility requirement to enforce explicit minimum contrast ratios, corrected muted-text token mappings, and contrast for the careers search/back-link, login forgot-password link, and dashboard heading exemplars. Also requires that unauthenticated/tenant-public pages (`/reset-password`, `/careers`, `/:tenant_slug/careers`, `/:tenant_slug/careers/:job_id`) expose the theme toggle and language switcher.
- `design-system`: Make button variant classes and badge classes theme-aware with dark overrides; document contrast-safe usage.
- `i18n`: Ensure all strings on `/:tenant_slug/careers/:job_id` (back link, "View other positions", closed/not-found headings) are wrapped with `gettext` with Italian translations so no English/Italian mix appears in any theme.
- `dashboard`: Ensure dashboard section headings and stats labels at `/:tenant_slug/app` carry explicit `dark:text-*` so they remain legible in dark mode.
- `authentication`: Ensure auth links (e.g., "Forgot your password?" on `/login`) have `dark:` overrides and remain contrast-compliant.
- `career-page`: Add a public header with homepage link + theme/language controls to `/careers` and `/:tenant_slug/careers*` pages so users can navigate home and change preferences without browser chrome.
- `public-job-board`: Same header coverage for the public job board surfaces (`/careers` and `/:tenant_slug/careers/:job_id/apply` as applicable).

## Impact

- **Code**: `lib/treby_web/components/design_system.ex` (variant/badge helpers), `lib/treby_web/components/design_system/*` (button/card/feedback/pattern), `lib/treby_web/components/core_components.ex` (inputs/table/typography), `lib/treby_web/components/layouts.ex` + `lib/treby_web/live/**/*` + `lib/treby_web/controllers/**/*` (muted text fixes), `assets/css/app.css` (dark tokens if needed).
- **Tooling**: `scripts/screenshots.mjs` (axe contrast enforcement), optional `mix precommit` / CI grep for `text-zinc-400 dark:text-zinc-500` anti-pattern.
- **Dependencies**: none new (uses existing `@axe-core/playwright` via `--axe`).
- **Migrations**: none.
- **Breaking changes**: none — visual-only contrast fixes; light theme appearance unchanged.
