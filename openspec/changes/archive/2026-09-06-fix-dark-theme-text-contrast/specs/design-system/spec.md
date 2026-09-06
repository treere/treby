## MODIFIED Requirements

### Requirement: Button component covers all app needs
The `TrebyWeb.DesignSystem.Button` component SHALL support variants `primary`/`secondary`/`danger`/`ghost`/`outline`, sizes `sm`/`md`/`lg`, `loading`, `disabled`, `icon` slot, and link modes (`href`/`navigate`/`patch`), with consistent bespoke Tailwind classes (not daisyUI `btn`/`btn-primary` contract) that are theme-aware with explicit `dark:` overrides. Primary SHALL be `zinc-900` (or `orange-600` for the main CTA emphasis) with `rounded-lg` and `shadow-sm`; secondary `white` with `border-zinc-200` and `dark:bg-zinc-800 dark:text-zinc-100 dark:border-zinc-700`; danger `red-600`; ghost `bg-transparent text-zinc-600 hover:bg-zinc-100` with `dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-zinc-100`; outline `bg-white text-zinc-700 border-zinc-300` with `dark:bg-zinc-800 dark:text-zinc-200 dark:border-zinc-600`. All variants SHALL meet WCAG AA contrast on their dark surfaces.

#### Scenario: Button renders all variants
- **WHEN** a developer renders `<.button>` with each variant and size
- **THEN** the correct bespoke classes appear (e.g., primary `bg-zinc-900 text-white hover:bg-zinc-800 rounded-lg shadow-sm`, secondary `bg-white border border-zinc-200` plus `dark:bg-zinc-800 dark:text-zinc-100 dark:border-zinc-700`) and the button is keyboard operable

#### Scenario: Loading button shows spinner and disables
- **WHEN** `loading={true}` is passed
- **THEN** a spinning `hero-arrow-path` icon appears and the control is disabled (`pointer-events-none opacity-60`)

#### Scenario: Button as link
- **WHEN** `navigate` or `href` is passed
- **THEN** the component renders a `<.link>` with the same visual classes instead of a `<button>`

#### Scenario: Secondary/ghost/outline remain legible in dark mode
- **WHEN** `variant="secondary"`, `"ghost"`, or `"outline"` is rendered on `bg-zinc-50 dark:bg-zinc-900` or inside `bg-white dark:bg-zinc-800` in dark mode
- **THEN** the computed text/background contrast is ≥4.5:1 (verified by axe `color-contrast`)

### Requirement: Badge component covers status use cases
The `TrebyWeb.DesignSystem.Badge` component SHALL support variants `default`/`success`/`warning`/`danger`/`info`, optional `dot` indicator, with SaaS minimal styling (`rounded-full`, `text-xs font-medium`, `border`, muted backgrounds like `bg-zinc-100 text-zinc-700 border-zinc-200` for default, `bg-emerald-50 text-emerald-700` for success, etc.) plus explicit `dark:` overrides (`dark:bg-zinc-700 dark:text-zinc-200 dark:border-zinc-600` for default, `dark:bg-emerald-950 dark:text-emerald-200 dark:border-emerald-800` for success, `dark:bg-amber-950 dark:text-amber-200` for warning, `dark:bg-red-950 dark:text-red-200` for danger, `dark:bg-blue-950 dark:text-blue-200` for info) that maintain WCAG AA contrast, and be used for all status/flag UI (e.g., NEW, DUPLICATE, role, stage) instead of raw spans.

#### Scenario: Badge renders variants
- **WHEN** a developer renders `<.badge>` with each variant
- **THEN** the correct bespoke `inline-flex rounded-full border text-xs font-medium` classes appear with both light and `dark:` overrides (not `badge badge-success`)

#### Scenario: No raw badge spans in app
- **WHEN** CI scans candidate and pipeline screens
- **THEN** flags like NEW/DUPLICATE are rendered via `<.badge>` not via `text-[10px] bg-red-100` spans

#### Scenario: Badges meet contrast in dark mode
- **WHEN** any badge variant is rendered inside `bg-white dark:bg-zinc-800` in dark mode
- **THEN** its text/background contrast is ≥4.5:1 (verified by axe, using the `dark:*` overrides that mirror `Feedback.toast` scale)

