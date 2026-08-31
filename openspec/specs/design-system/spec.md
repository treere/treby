# Design System

## Purpose

Provide a single, theme-aware design system (`TrebyWeb.DesignSystem.*` + `assets/css/app.css` tokens) that is the authoritative source for all UI primitives and components, ensuring visual consistency, accessibility, and maintainability across the application.

## Requirements

### Requirement: Single design-system source of truth
The system SHALL provide a single design system under `TrebyWeb.DesignSystem.*` and `assets/css/app.css` tokens that is the only place defining visual primitives (spacing, typography, color semantic, radius, shadow) and component styles. No screen SHALL define ad-hoc button/badge/card/modal styles outside the design system.

#### Scenario: Tokens are centralized
- **WHEN** a developer inspects `assets/css/app.css`
- **THEN** spacing (`--ds-space-*`), typography (`--ds-font-*`, `--ds-text-*`), radius (`--ds-radius-*`), and shadow (`--ds-shadow-*`) tokens are defined for both light and dark themes

#### Scenario: No ad-hoc button styling in app code
- **WHEN** CI scans `lib/treby_web` (excluding `lib/treby_web/components/design_system/*`)
- **THEN** no file contains hardcoded `bg-blue-600 text-white px-3 py-1 rounded` or `bg-gray-500` button markup

### Requirement: Design-system tokens are theme-aware
The system SHALL define tokens that resolve correctly in both light and dark themes via `data-theme` / `prefers-color-scheme`, with no hardcoded `gray-50` / `gray-900` surfaces in layouts or portal outside the token set.

#### Scenario: Portal uses semantic tokens
- **WHEN** a user views the candidate portal in dark mode
- **THEN** surfaces use `base-100`/`base-200`/`base-300` and `base-content` via tokens, not hardcoded `gray-50`/`gray-900`

#### Scenario: Shadows adapt to theme
- **WHEN** the theme switches from light to dark
- **THEN** `--ds-shadow-*` values switch to the dark-theme definitions

### Requirement: Button component covers all app needs
The `TrebyWeb.DesignSystem.Button` component SHALL support variants `primary`/`secondary`/`danger`/`ghost`/`outline`, sizes `sm`/`md`/`lg`, `loading`, `disabled`, `icon` slot, and link modes (`href`/`navigate`/`patch`), with consistent Tailwind classes via `variant_classes/1` and `size_classes/1`.

#### Scenario: Button renders all variants
- **WHEN** a developer renders `<.button>` with each variant and size
- **THEN** the correct `btn` / `btn-primary` / `btn-error` / `btn-ghost` / `btn-outline` and size classes appear and the button is keyboard operable

#### Scenario: Loading button shows spinner and disables
- **WHEN** `loading={true}` is passed
- **THEN** a spinning `hero-arrow-path` icon appears and the control is disabled (`pointer-events-none opacity-60`)

#### Scenario: Button as link
- **WHEN** `navigate` or `href` is passed
- **THEN** the component renders a `<.link>` with the same visual classes instead of a `<button>`

### Requirement: Badge component covers status use cases
The `TrebyWeb.DesignSystem.Badge` component SHALL support variants `default`/`success`/`warning`/`danger`/`info`, optional `dot` indicator, and be used for all status/flag UI (e.g., NEW, DUPLICATE, role, stage) instead of raw spans.

#### Scenario: Badge renders variants
- **WHEN** a developer renders `<.badge>` with each variant
- **THEN** the correct `badge` / `badge-success` / `badge-warning` / `badge-error` / `badge-info` classes appear

#### Scenario: No raw badge spans in app
- **WHEN** CI scans candidate and pipeline screens
- **THEN** flags like NEW/DUPLICATE are rendered via `<.badge>` not via `text-[10px] bg-red-100` spans

### Requirement: Full component catalog is available
The design system SHALL provide `Card` (variants `default`/`bordered`/`elevated`/`flat` with `header`/`footer` slots), `Modal` (sizes `sm`/`md`/`lg`/`xl`, backdrop + Escape + focus), `Dropdown`, `Tabs`, `Avatar`, `Feedback` (`Spinner` sizes `sm`/`md`/`lg`, `Skeleton` variants `text`/`avatar`/`card`, `Toast` kinds `info`/`success`/`warning`/`error`), and `Pattern` (`ConfirmDialog`, `PageHeader` with breadcrumbs, `EmptyState`, `FilterBar`, `FormSection`, `LoadingOverlay`), each theme-aware and accessible.

#### Scenario: Card and modal render correctly
- **WHEN** a developer renders `<.card>` and `<.modal>` with headers/footers/overlays
- **THEN** they appear with correct `card`/`modal` classes, rounded boxes, borders, and dark-mode surfaces

#### Scenario: Pattern components cover app screens
- **WHEN** a settings or candidate screen needs a page header, empty state, filter bar, or form section
- **THEN** it uses `Pattern.page_header` / `empty_state` / `filter_bar` / `form_section` instead of custom markup

### Requirement: App UI migrates 100% to the design system
Every screen in `lib/treby_web/live/**/*`, `lib/treby_web/controllers/**/*`, and `lib/treby_web/components/layouts.ex` SHALL use the design-system components for buttons, badges, cards, modals/confirms, page headers, empty states, filters, and loading states.

#### Scenario: Settings screens use DS
- **WHEN** a user views any `settings_live/*` page
- **THEN** all buttons, confirms, headers, and forms use DS components (no `bg-gray-500` cancel buttons remain)

#### Scenario: Candidates/jobs/pipeline use DS
- **WHEN** a user views candidates, jobs, or pipeline boards
- **THEN** all CTAs, badges, cards, and dialogs use DS components

#### Scenario: Candidate portal and auth use DS
- **WHEN** a user views `candidate_portal_live/*` or login/register/verify pages
- **THEN** all CTAs use DS button styles (no raw `bg-blue-600` markup)

### Requirement: Legacy shims are removed
The delegating shims `CoreComponents.button/empty_state/confirm_modal` SHALL be removed after migration, and all imports SHALL reference `TrebyWeb.DesignSystem.*` directly, with no consumer breakage.

#### Scenario: Shims removed cleanly
- **WHEN** `mix compile` runs after migration
- **THEN** there are no warnings about missing `CoreComponents.button`/`confirm_modal`/`empty_state` and `mix precommit` passes

### Requirement: Guardrail prevents regressions
The repository SHALL enforce that new code does not reintroduce hardcoded design-system styles outside `design_system/*` via a CI check (grep or Credo rule).

#### Scenario: CI fails on hardcoded styles
- **WHEN** a PR introduces `bg-blue-600` or `bg-gray-500` button markup outside `lib/treby_web/components/design_system`
- **THEN** CI fails with a message pointing to the design-system component to use instead

#### Scenario: Guardrail is documented
- **WHEN** a developer reads `README.md` or `AGENTS.md`
- **THEN** the DS usage rule and the guardrail command are documented
