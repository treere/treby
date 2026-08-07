## 1. Wire the toggle into navigation

- [x] 1.1 Render `<.theme_toggle />` in the desktop nav in `lib/treby_web/components/layouts.ex`, immediately before `<.locale_switcher />` (line ~111).
- [x] 1.2 Render `<.theme_toggle />` in the mobile drawer in `lib/treby_web/components/layouts.ex`, immediately before `<.locale_switcher locale={@locale} id_suffix="-mobile" />` (line ~219).
- [x] 1.3 Verify the existing `theme_toggle` component classes (e.g. `card`, `border-1`) are present in the compiled CSS; adjust to Tailwind-compatible classes if any are dropped.

## 2. Harden the theme bootstrap script

- [x] 2.1 In `lib/treby_web/components/layouts/root.html.heex`, wrap `localStorage` access in the inline script in try/catch so it degrades gracefully when storage is unavailable.
- [x] 2.2 Add a `matchMedia("(prefers-color-scheme: ...)")` listener so the theme updates live when the OS scheme changes while in "system" mode.
- [x] 2.3 Confirm the script still runs before the stylesheet link (no flash of incorrect theme) and handles both existing and new `data-theme` states.

## 3. Convert layouts and core components to theme-aware tokens

- [x] 3.1 In `lib/treby_web/components/layouts.ex`: `bg-gray-50` → `bg-base-200`, `bg-white` → `bg-base-100`, `text-gray-*` → `text-base-content` (+ opacity tiers), `border-gray-*` → `border-base-300`, and adapt the mobile drawer/nav hover states.
- [x] 3.2 In `lib/treby_web/components/core_components.ex`: replace hardcoded grays/blues/whites in the event timeline, onboarding card, and any other light-only spots with `base-*`/`base-content` tokens or `dark:` variants.
- [x] 3.3 Grep `lib/treby_web` for remaining `bg-white|bg-gray-50|bg-gray-100|text-gray-[4-9]00|border-gray-[12]00` and confirm only intentional occurrences remain.

## 4. Convert auth and static pages

- [x] 4.1 Update `lib/treby_web/controllers/session_html/new.html.heex`, `registration_html/new.html.heex`, `password_reset_html/new.html.heex` and `edit.html.heex` (page background, card, headings, inputs, labels) to theme-aware tokens.
- [x] 4.2 Update `lib/treby_web/controllers/invite_html/show.html.heex` and `static_page_html/{privacy,terms}.html.heex` similarly.

## 5. Convert feature LiveViews

- [x] 5.1 Convert `dashboard_live.ex`, `home_live.ex`, and `jobs_live/*` (including show/index).
- [x] 5.2 Convert `candidates_live/*` (index, show, merge) and `import_live/index.ex`.
- [x] 5.3 Convert `pipeline_live/*`, `interviews_live/index.ex`, and `schedule_live/index.ex`.
- [x] 5.4 Convert `analytics_live/index.ex`, `email_queue_live/index.html.heex`, and `schedule_picker.ex`.
- [x] 5.5 Convert `settings_live/*` (index, language, team, branding, calendar, pipeline, pipeline_stages, sources, notifications, email_templates, fields, scorecards, availability) and `careers_live/*`, `scheduling_live/booking.ex`, `comparison_live/index.ex`.

## 6. Verify in both themes

- [x] 6.1 Run `mix precommit` and fix any failures.
- [x] 6.2 Boot the app and manually verify key pages (dashboard, jobs, candidates, pipeline, email queue, settings, auth pages) in light, dark, and system modes, checking contrast and that no element is invisible in either theme.

## 7. Docs site

- [x] 7.1 Regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 7.2 Update the relevant `site/features/` page(s) to document dark mode and the toggle location; include the new screenshots.

## 8. Unauthenticated pages

- [x] 8.1 Add the theme toggle and locale switcher to the login page (`session_html/new.html.heex`).
- [x] 8.2 Add the theme toggle and locale switcher to the register page (`registration_html/new.html.heex`).
- [x] 8.3 Add the theme toggle and locale switcher to the forgot password pages (`password_reset_html/new.html.heex` and `edit.html.heex`).
- [x] 8.4 Add the theme toggle to the homepage header in `home_live.ex`, next to the locale switcher.
- [x] 8.5 Ensure the theme toggle works on non-LiveView pages (the `phx-click` dispatch is not processed outside a LiveView root; wire a document-level click listener or equivalent in `root.html.heex`).
- [x] 8.6 Run `mix precommit` and verify the toggles in the browser.
