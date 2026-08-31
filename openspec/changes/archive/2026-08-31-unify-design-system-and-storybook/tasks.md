## 1. Storybook foundation (dev-only)

- [x] 1.1 Add `{:phoenix_storybook, "~> 0.9", only: :dev}` to `mix.exs` deps, run `mix deps.get`, verify `mix compile` passes in `dev`/`test`/`prod`
- [x] 1.2 Create `lib/treby_web/storybook.ex` implementing `PhoenixStorybook.Storybook` with `content_path: "storybook"`, `entries: storybook/**`, `css_path` to `assets/css/app.css` if needed
- [x] 1.3 Mount storybook dev-only in `lib/treby_web/router.ex` — `import PhoenixStorybook.Router` + `scope "/dev/storybook", TrebyWeb do pipe_through :browser; live_storybook("/dev/storybook", :storybook) end` guarded by `if Application.compile_env(:treby, :dev_routes)` (dev-only), verify 404 at `/storybook` and `MIX_ENV=prod` and `mix test` still green
- [x] 1.4 Verify storybook renders at `http://localhost:4000/dev/storybook` in `MIX_ENV=dev`, respects `data-theme` (light/dark/system), and is excluded from `Dockerfile` prod stage / `mix release`

## 2. Design-system token & component hardening

- [x] 2.1 Normalize `assets/css/app.css` tokens — keep Tailwind v4 `@import "tailwindcss" source(none); @source "../css"; @source "../js"; @source "../../lib/treby_web";`, consolidate `--ds-space-*`/`--ds-font-*`/`--ds-text-*`/`--ds-radius-*`/`--ds-shadow-*` with light/dark values via `data-theme`/`prefers-color-scheme`, map remaining `gray-50`/`gray-900` surfaces to `base-100/200/300` + `base-content`
- [x] 2.2 Harden `TrebyWeb.DesignSystem.Button` — verify variants `primary/secondary/danger/ghost/outline`, sizes `sm/md/lg`, `loading` (spinner + disabled), `disabled`, `icon` slot, `href/navigate/patch` link mode, focus-visible; fix any missing `variant_classes/1`/`size_classes/1` mapping
- [x] 2.3 Harden `TrebyWeb.DesignSystem.Badge` — variants `default/success/warning/danger/info`, `dot`, ensure contrast in dark mode
- [x] 2.4 Harden `Card`/`Modal`/`Dropdown`/`Tabs`/`Avatar` — add missing props (Card variants `default/bordered/elevated/flat`; Modal sizes `sm/md/lg/xl`, backdrop + Escape + `JS.focus()` trap; Dropdown `align`; Tabs roving tabindex; Avatar `size`/`src`/`initials`), verify keyboard a11y
- [x] 2.5 Harden `Feedback` (`Spinner`/`Skeleton`/`Toast`) and `Pattern` (`ConfirmDialog`/`PageHeader`/`EmptyState`/`FilterBar`/`FormSection`/`LoadingOverlay`) — ensure `Toast` kinds `info/success/warning/error` use `alert-*` tokens, `ConfirmDialog` `confirm_variant` + `extra_attrs`, `PageHeader` breadcrumbs, `FilterBar` `on_change/on_reset`, `FormSection` grouping, `LoadingOverlay` dim + spinner

## 3. Storybook stories for every DS component

- [x] 3.1 Create `storybook/button.story.exs`, `storybook/badge.story.exs`, `storybook/card.story.exs`, `storybook/modal.story.exs` with variant/size/boolean controls
- [x] 3.2 Create `storybook/dropdown.story.exs`, `storybook/tabs.story.exs`, `storybook/avatar.story.exs`
- [x] 3.3 Create `storybook/feedback.story.exs` (`Spinner` sizes `sm/md/lg`, `Skeleton` variants `text/avatar/card`, `Toast` kinds `info/success/warning/error` with/without `title`)
- [x] 3.4 Create `storybook/pattern.story.exs` or `storybook/patterns/*.story.exs` covering `ConfirmDialog` (variants, `show`, `extra_attrs`), `PageHeader` (breadcrumbs/subtitle/actions), `EmptyState`, `FilterBar`, `FormSection`, `LoadingOverlay` — each with light/dark preview note
- [x] 3.5 Cross-check all stories render correctly in light/dark and controls propagate to the component

## 4. Migrate app UI to the design system (batched)

- [x] 4.1 Migrate `lib/treby_web/live/settings_live/*` (fields, sources, pipeline, calendar, availability, email_templates, pipeline_stages, scorecards, team, branding, notifications, language) — replace `bg-gray-500`, `bg-blue-600`/`bg-green-600`/`bg-purple-600 text-white px-3 py-1`, raw badge spans with `<.button>`/`<.badge>`/`<.page_header>`/`<.form_section>`/`<.confirm_dialog>`
- [x] 4.2 Migrate `lib/treby_web/live/candidates_live/*`, `lib/treby_web/live/jobs_live/*`, `lib/treby_web/live/pipeline_live/index.ex` — replace candidate card badges (`NEW`/`DUPLICATE`), stage/role buttons, confirm flows with DS components
- [x] 4.3 Migrate `lib/treby_web/live/interviews_live/index.ex`, `lib/treby_web/live/schedule_live/index.ex`, `lib/treby_web/live/analytics_live/index.ex`, `lib/treby_web/live/dashboard_live.ex`, `lib/treby_web/live/import_live/index.ex` — filters, empty states, page headers
- [x] 4.4 Migrate `lib/treby_web/live/candidate_portal_live/*` and `lib/treby_web/live/careers_live/*` — map `bg-gray-50 dark:bg-gray-900` to `base-*` tokens, replace raw `bg-blue-600` CTAs with DS buttons
- [x] 4.5 Migrate `lib/treby_web/controllers/**/*.html.heex` (session, registration, password_reset, invite, static_page) and `lib/treby_web/components/layouts.ex` / `layouts/root.html.heex` — normalize nav, auth toolbar, locale/theme toggles, portal/landing layouts to DS tokens

## 5. Remove legacy shims and consolidate

- [x] 5.1 Remove `CoreComponents.button` shim (delegating to `DesignSystem.Button`) — update all call sites to import `TrebyWeb.DesignSystem.Button` directly; ensure `core_components.ex` no longer aliases `Button`/`Pattern` for those
- [x] 5.2 Replace remaining `CoreComponents.confirm_modal` / `empty_state` usages with `Pattern.confirm_dialog` / `Pattern.empty_state` and drop the shim functions (keep `flash`/`input`/`icon`/`header`/`table` where still needed or consolidate `header` → `PageHeader`)
- [x] 5.3 Remove any remaining hardcoded `bg-gray-*` / `bg-blue-600` remnants in `lib/treby_web` outside `design_system/*` and `assets/css/app.css`; `rg` scan should return empty

## 6. Guardrail, docs, and spec sync

- [x] 6.1 Add CI guard — `grep -R "bg-blue-600.*text-white.*px-3" lib/treby_web --include="*.ex" --include="*.heex"` and `grep -R "bg-gray-500" ...` (excluding `design_system/*`) must be empty, or a `Treby.Credo.Checks.DesignSystemUsage` custom check; wire into `mix precommit` or `.github/workflows/*`
- [x] 6.2 Update `README.md` with storybook dev URL (`http://localhost:4000/dev/storybook`, `MIX_ENV=dev` only, not in prod) and DS usage note
- [x] 6.3 Sync specs — run `openspec sync` or manually update `openspec/specs/design-system/spec.md`, `openspec/specs/storybook-preview/spec.md`, `openspec/specs/dark-mode/spec.md`, `openspec/specs/error-feedback/spec.md`, `openspec/specs/delete-confirmations/spec.md` with Purpose/Requirements and WHEN/THEN scenarios; update `site/` only if user-facing behavior changes per `AGENTS.md` (otherwise keep `site/` as user manual, no code internals)

## 7. Verification

- [x] 7.1 Run `mix test` (full suite) and `mix compile --warnings-as-errors` in `dev`/`test`/`prod`; verify storybook 404s in `prod`
- [x] 7.2 Manual QA: open each migrated screen in light and dark (`data-theme` toggle + system), check buttons/badges/cards/modals/tables/forms legibility and focus management; open every storybook story and toggle controls/variants
- [x] 7.3 Run `mix precommit` and `openspec validate --strict` and fix issues
