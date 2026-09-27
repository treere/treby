## MODIFIED Requirements

### Requirement: Badge component covers status use cases
The `TrebyWeb.DesignSystem.Badge` component SHALL support variants `default`/`success`/`warning`/`danger`/`info`, optional `dot` indicator, with SaaS minimal styling (`rounded-full`, `text-xs font-medium`, `border`, muted backgrounds like `bg-zinc-100 text-zinc-700 border-zinc-200` for default, `bg-emerald-50 text-emerald-700` for success, etc.), and be used for all status/flag UI (e.g., NEW, DUPLICATE, role, stage) instead of raw spans. The system SHALL provide a single `TrebyWeb.DesignSystem.status_variant/1` mapping (status string/atom → `"default" | "success" | "warning" | "danger" | "info"`) and a thin `<.status_badge status={...} label={...} dot={...}>` that renders `<.badge variant={status_variant(status)}>`. No LiveView SHALL define its own inline status-to-variant `case` mapping or duplicate badge color maps (including the `candidate_portal_live` duplicate); all call sites SHALL use `<.status_badge>` (or `<.badge variant={...}>` for one-off non-status colors).

#### Scenario: Badge renders variants
- **WHEN** a developer renders `<.badge>` with each variant
- **THEN** the correct bespoke `inline-flex rounded-full border text-xs font-medium` classes appear (not `badge badge-success`)

#### Scenario: No raw badge spans in app
- **WHEN** CI scans candidate and pipeline screens
- **THEN** flags like NEW/DUPLICATE are rendered via `<.badge>` not via `text-[10px] bg-red-100` spans

#### Scenario: Badges meet contrast in dark mode
- **WHEN** any badge variant is rendered inside `bg-white dark:bg-zinc-800` in dark mode
- **THEN** its text/background contrast is ≥4.5:1 (verified by axe, using the `dark:*` overrides that mirror `Feedback.toast` scale)

#### Scenario: Status mapping is centralized
- **WHEN** any screen renders a domain status (job, candidate, application, pipeline stage)
- **THEN** it calls `<.status_badge status={status}>` and no file outside `design_system/*` contains an inline status-to-color `case` (e.g. `case status do ... "emerald" ... "amber" ...`)

### Requirement: App UI migrates 100% to the design system
Every screen in `lib/treby_web/live/**/*`, `lib/treby_web/controllers/**/*`, and `lib/treby_web/components/layouts.ex` SHALL use the design-system components for buttons, badges, cards, modals/confirms, page headers, empty states, filters, and loading states. Tables SHALL use `hover:bg-zinc-50` with `border-b border-zinc-100` rows and `text-xs font-medium text-zinc-500 uppercase` headers (not `table-zebra`). Kanban columns SHALL use `bg-zinc-50 rounded-xl border border-zinc-200` and cards `bg-white rounded-lg border shadow-sm hover:shadow-md`. Card call sites SHALL use `<.card variant={...}>` with `<:header>` / `<:footer>` slots (default panels → `default`; stronger border → `bordered`; highlights → `elevated`; nested → `flat`). Form inputs SHALL use `to_form/2`-driven `<.input field={@form[:x]}>` where a form exists, otherwise bare tags styled only via `DesignSystem.input_classes/1` / `select_classes/1` / `textarea_classes/1`, grouped via `Pattern.form_section` / `Pattern.filter_bar`. No screen SHALL keep a raw `<table>`; all lists SHALL use core `<.table id rows row_id row_click :col :action>` preserving existing DOM ids and stream assigns. No screen SHALL keep a raw modal shell; dialogs SHALL use `<.modal id show title size close_event>` and confirms SHALL use `Pattern.confirm_dialog` keeping existing event names verbatim.

#### Scenario: Settings screens use DS
- **WHEN** a user views any `settings_live/*` page
- **THEN** all buttons, confirms, headers, and forms use DS components (no `bg-gray-500` cancel buttons remain) with SaaS minimal styling

#### Scenario: Candidates/jobs/pipeline use DS
- **WHEN** a user views candidates, jobs, or pipeline boards
- **THEN** all CTAs, badges, cards, and dialogs use DS components; pipeline columns/cards use the new rounded-xl / shadow-sm language

#### Scenario: Candidate portal and auth use DS
- **WHEN** a user views `candidate_portal_live/*` or login/register/verify pages
- **THEN** all CTAs use DS button styles (not raw `bg-blue-600` markup) with SaaS minimal styling

#### Scenario: Cards use DS card
- **WHEN** CI scans LiveViews for card shells (`bg-white dark:bg-zinc-800 rounded-xl border`)
- **THEN** no match exists outside `design_system/*`; each panel renders via `<.card>`

#### Scenario: Inputs use DS input tokens
- **WHEN** a form or filter bar renders an input, select, or textarea
- **THEN** it uses `<.input>` or classes from `input_classes` / `select_classes` / `textarea_classes`, and renders identically in light and dark themes

#### Scenario: Tables use DS table
- **WHEN** a user views jobs, candidates, team, audit log, or webhooks lists
- **THEN** rows have `border-b border-zinc-100` with `hover:bg-zinc-50`, headers are `text-xs font-medium text-zinc-500 uppercase tracking-wider`, streams and `row_click` still work, and no raw `<table>` remains

#### Scenario: Modals use DS modal
- **WHEN** a user opens scorecard, pipeline, candidate-show, or layout dialogs
- **THEN** backdrop, Escape, focus, and close/cancel events behave as before via `<.modal>` / `<.confirm_dialog>` with no raw `fixed inset-0 z-50` shell outside `design_system/*`

### Requirement: Guardrail prevents regressions
The repository SHALL enforce that new code does not reintroduce hardcoded design-system styles or daisyUI class contracts outside `design_system/*` via a CI check (grep or Credo rule) that fails on `bg-blue-600`, `bg-gray-500`, `btn btn-primary`, `badge badge-`, `table-zebra` outside the DS. The `treby.check_design_system` task SHALL additionally fail on copied card shells (`bg-white dark:bg-zinc-800 rounded-xl border`), raw `<table>`, raw modal shells (`fixed inset-0 z-50` / backdrop + `max-h-[85vh]`), raw `<input|select|textarea class=` without `input_classes|select_classes|textarea_classes|filter_bar|<.input` in the same file, and copied badge color spans / inline status-to-variant `case` maps outside `design_system/*`.

#### Scenario: CI fails on hardcoded styles
- **WHEN** a PR introduces `bg-blue-600` or `btn btn-primary` button markup outside `lib/treby_web/components/design_system`
- **THEN** CI fails with a message pointing to the design-system component to use instead

#### Scenario: Guardrail is documented
- **WHEN** a developer reads `README.md` or `AGENTS.md`
- **THEN** the DS usage rule (SaaS minimal tokens, no daisyUI contract) and the guardrail command are documented

#### Scenario: Guardrail flags raw copies
- **WHEN** a PR adds a raw `<table>`, raw modal shell, copied card shell, raw classified input, or inline status-color `case` outside `design_system/*`
- **THEN** `mix treby.check_design_system` (via `mix precommit` / pre-push / CI) fails with `file: pattern-name` pointing at `Card` / `<.table>` / `<.modal>` / `input_classes` / `<.status_badge>` instead
