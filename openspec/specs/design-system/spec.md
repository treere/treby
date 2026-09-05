# Design System

## Purpose

Provide a single, theme-aware design system (`TrebyWeb.DesignSystem.*` + `assets/css/app.css` tokens) that is the authoritative source for all UI primitives and components, ensuring visual consistency, accessibility, and maintainability across the application.
## Requirements
### Requirement: Single design-system source of truth
The system SHALL provide a single design system under `TrebyWeb.DesignSystem.*` and `assets/css/app.css` tokens that is the only place defining visual primitives (spacing, typography, color semantic, radius, shadow) and component styles, using a bespoke Modern SaaS Minimal language (zinc neutrals, white cards, hairline borders, soft shadows, rounded-xl) with no dependency on daisyUI class semantics. No screen SHALL define ad-hoc button/badge/card/modal styles outside the design system.

#### Scenario: Tokens are centralized and SaaS-minimal
- **WHEN** a developer inspects `assets/css/app.css`
- **THEN** spacing (`--ds-space-*`), typography (`--ds-font-*`, `--ds-text-*`), radius (`--ds-radius-*` with box `0.75rem`/field `0.5rem`), and shadow (`--ds-shadow-*` with `sm` default) tokens are defined for both light and dark themes in the Modern SaaS Minimal palette (light: page `zinc-50`/card `white`/border `zinc-200`/text `zinc-900`; dark: page `zinc-900`/card `zinc-800`/border `zinc-700`), and no `daisyUI` theme variable (`--color-base-*`, `--radius-box:0.25rem`, `--depth:1`) is the source of truth

#### Scenario: No ad-hoc button styling in app code
- **WHEN** CI scans `lib/treby_web` (excluding `lib/treby_web/components/design_system/*`)
- **THEN** no file contains hardcoded `bg-blue-600 text-white px-3 py-1 rounded` or `bg-gray-500` or `btn btn-primary` button markup

### Requirement: Design-system tokens are theme-aware
The system SHALL define tokens that resolve correctly in both light and dark themes via `data-theme` / `prefers-color-scheme`, with no hardcoded `gray-50` / `gray-900` surfaces in layouts or portal outside the token set. Light theme SHALL use `zinc-50` page background with `white` card surfaces and `zinc-200` borders; dark theme SHALL use `zinc-900` page with `zinc-800` cards and `zinc-700` borders.

#### Scenario: Portal uses semantic tokens
- **WHEN** a user views the candidate portal in dark mode
- **THEN** surfaces use the SaaS minimal dark tokens (`zinc-800`/`zinc-900`/`zinc-700` + `zinc-100` content) via tokens, not hardcoded `gray-50`/`gray-900` or `base-100`/`base-200`

#### Scenario: Shadows adapt to theme
- **WHEN** the theme switches from light to dark
- **THEN** `--ds-shadow-*` values switch to the dark-theme definitions (softer, higher opacity) and cards retain `shadow-sm` hierarchy

### Requirement: Button component covers all app needs
The `TrebyWeb.DesignSystem.Button` component SHALL support variants `primary`/`secondary`/`danger`/`ghost`/`outline`, sizes `sm`/`md`/`lg`, `loading`, `disabled`, `icon` slot, and link modes (`href`/`navigate`/`patch`), with consistent bespoke Tailwind classes (not daisyUI `btn`/`btn-primary` contract). Primary SHALL be `zinc-900` (or `orange-600` for the main CTA emphasis) with `rounded-lg` and `shadow-sm`; secondary `white` with `border-zinc-200`; danger `red-600`; ghost/outline use neutral borders.

#### Scenario: Button renders all variants
- **WHEN** a developer renders `<.button>` with each variant and size
- **THEN** the correct bespoke classes appear (e.g., primary `bg-zinc-900 text-white hover:bg-zinc-800 rounded-lg shadow-sm`, secondary `bg-white border border-zinc-200`) and the button is keyboard operable

#### Scenario: Loading button shows spinner and disables
- **WHEN** `loading={true}` is passed
- **THEN** a spinning `hero-arrow-path` icon appears and the control is disabled (`pointer-events-none opacity-60`)

#### Scenario: Button as link
- **WHEN** `navigate` or `href` is passed
- **THEN** the component renders a `<.link>` with the same visual classes instead of a `<button>`

### Requirement: Badge component covers status use cases
The `TrebyWeb.DesignSystem.Badge` component SHALL support variants `default`/`success`/`warning`/`danger`/`info`, optional `dot` indicator, with SaaS minimal styling (`rounded-full`, `text-xs font-medium`, `border`, muted backgrounds like `bg-zinc-100 text-zinc-700 border-zinc-200` for default, `bg-emerald-50 text-emerald-700` for success, etc.), and be used for all status/flag UI (e.g., NEW, DUPLICATE, role, stage) instead of raw spans.

#### Scenario: Badge renders variants
- **WHEN** a developer renders `<.badge>` with each variant
- **THEN** the correct bespoke `inline-flex rounded-full border text-xs font-medium` classes appear (not `badge badge-success`)

#### Scenario: No raw badge spans in app
- **WHEN** CI scans candidate and pipeline screens
- **THEN** flags like NEW/DUPLICATE are rendered via `<.badge>` not via `text-[10px] bg-red-100` spans

### Requirement: Full component catalog is available
The design system SHALL provide `Card` (variants `default`/`bordered`/`elevated`/`flat` with `header`/`footer` slots, styled as `bg-white rounded-xl border border-zinc-200 shadow-sm` with header `border-b border-zinc-100`), `Modal` (sizes `sm`/`md`/`lg`/`xl`, backdrop + Escape + focus, `rounded-xl shadow-xl`), `Dropdown`, `Tabs`, `Avatar`, `Feedback` (`Spinner` sizes `sm`/`md`/`lg`, `Skeleton` variants `text`/`avatar`/`card`, `Toast` kinds `info`/`success`/`warning`/`error`), and `Pattern` (`ConfirmDialog`, `PageHeader` with breadcrumbs, `EmptyState`, `FilterBar`, `FormSection`, `LoadingOverlay`), each theme-aware and accessible in the SaaS minimal language.

#### Scenario: Card and modal render correctly
- **WHEN** a developer renders `<.card>` and `<.modal>` with headers/footers/overlays
- **THEN** they appear with `bg-white rounded-xl border border-zinc-200 shadow-sm` (card) and `rounded-xl shadow-xl` (modal) styling, with dark-mode `bg-zinc-800 border-zinc-700` surfaces

#### Scenario: Pattern components cover app screens
- **WHEN** a settings or candidate screen needs a page header, empty state, filter bar, or form section
- **THEN** it uses `Pattern.page_header` / `empty_state` / `filter_bar` / `form_section` instead of custom markup, all in the SaaS minimal style

### Requirement: App UI migrates 100% to the design system
Every screen in `lib/treby_web/live/**/*`, `lib/treby_web/controllers/**/*`, and `lib/treby_web/components/layouts.ex` SHALL use the design-system components for buttons, badges, cards, modals/confirms, page headers, empty states, filters, and loading states. Tables SHALL use `hover:bg-zinc-50` with `border-b border-zinc-100` rows and `text-xs font-medium text-zinc-500 uppercase` headers (not `table-zebra`). Kanban columns SHALL use `bg-zinc-50 rounded-xl border border-zinc-200` and cards `bg-white rounded-lg border shadow-sm hover:shadow-md`.

#### Scenario: Settings screens use DS
- **WHEN** a user views any `settings_live/*` page
- **THEN** all buttons, confirms, headers, and forms use DS components (no `bg-gray-500` cancel buttons remain) with SaaS minimal styling

#### Scenario: Candidates/jobs/pipeline use DS
- **WHEN** a user views candidates, jobs, or pipeline boards
- **THEN** all CTAs, badges, cards, and dialogs use DS components; pipeline columns/cards use the new rounded-xl / shadow-sm language

#### Scenario: Candidate portal and auth use DS
- **WHEN** a user views `candidate_portal_live/*` or login/register/verify pages
- **THEN** all CTAs use DS button styles (not raw `bg-blue-600` markup) with SaaS minimal styling

### Requirement: Legacy shims are removed
The delegating shims `CoreComponents.button/empty_state/confirm_modal` SHALL be removed after migration, and all imports SHALL reference `TrebyWeb.DesignSystem.*` directly, with no consumer breakage.

#### Scenario: Shims removed cleanly
- **WHEN** `mix compile` runs after migration
- **THEN** there are no warnings about missing `CoreComponents.button`/`confirm_modal`/`empty_state` and `mix precommit` passes

### Requirement: Guardrail prevents regressions
The repository SHALL enforce that new code does not reintroduce hardcoded design-system styles or daisyUI class contracts outside `design_system/*` via a CI check (grep or Credo rule) that fails on `bg-blue-600`, `bg-gray-500`, `btn btn-primary`, `badge badge-`, `table-zebra` outside the DS.

#### Scenario: CI fails on hardcoded styles
- **WHEN** a PR introduces `bg-blue-600` or `btn btn-primary` button markup outside `lib/treby_web/components/design_system`
- **THEN** CI fails with a message pointing to the design-system component to use instead

#### Scenario: Guardrail is documented
- **WHEN** a developer reads `README.md` or `AGENTS.md`
- **THEN** the DS usage rule (SaaS minimal tokens, no daisyUI contract) and the guardrail command are documented

### Requirement: SaaS minimal visual language and page surfaces
The system SHALL use the Modern SaaS Minimal page language: page background `zinc-50` (light) / `zinc-900` (dark), card surface `white` / `zinc-800`, hairline `border-zinc-200` / `zinc-700`, `shadow-sm` default with `shadow-md` on hover/drag, radii `0.75rem` (box) / `0.5rem` (field), and accent `orange-600` reserved for primary CTA.

#### Scenario: Page and card surfaces are SaaS minimal
- **WHEN** a user views any app page (dashboard, jobs, candidates)
- **THEN** the page background is `bg-zinc-50` (light) / `bg-zinc-900` (dark) and cards are `bg-white rounded-xl border border-zinc-200 shadow-sm` (light) — not `bg-base-200` / `bg-base-100 shadow`

#### Scenario: Tables use minimal styling
- **WHEN** a user views a jobs or candidates table
- **THEN** rows have `border-b border-zinc-100` with `hover:bg-zinc-50`, header is `text-xs font-medium text-zinc-500 uppercase tracking-wider`, and no `table-zebra` striping is present

### Requirement: daisyUI off-ramp
The codebase SHALL NOT rely on daisyUI theme variables (`--color-base-*`, `--radius-selector`, `--depth`, `--noise`) or daisyUI class contract (`btn btn-primary`, `badge badge-success`, `card`, `table table-zebra`) as the styling source of truth. daisyUI MAY remain installed during migration for backward compat but SHALL be removable without visual change once DS class output is migrated.

#### Scenario: daisyUI is removable
- **WHEN** `@plugin "daisyui"` is removed from `assets/css/app.css` after migration
- **THEN** `mix assets.build` still succeeds and no screen visually regresses (verified by Playwright screenshot comparison)

