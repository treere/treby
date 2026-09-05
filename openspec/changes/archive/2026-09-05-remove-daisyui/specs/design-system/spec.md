## MODIFIED Requirements

### Requirement: SaaS minimal visual language and page surfaces
The system SHALL use the Modern SaaS Minimal page language: page background `zinc-50` (light) / `zinc-900` (dark), card surface `white` / `zinc-800`, hairline `border-zinc-200` / `zinc-700`, `shadow-sm` default with `shadow-md` on hover/drag, radii `0.75rem` (box) / `0.5rem` (field), and accent `orange-600` reserved for primary CTA, with no daisyUI plugin or `daisyUI` npm package in the build pipeline.

#### Scenario: Page and card surfaces are SaaS minimal
- **WHEN** a user views any app page (dashboard, jobs, candidates)
- **THEN** the page background is `bg-zinc-50` (light) / `bg-zinc-900` (dark) and cards are `bg-white rounded-xl border border-zinc-200 shadow-sm` (light) — not `bg-base-200` / `bg-base-100 shadow`

#### Scenario: Tables use minimal styling
- **WHEN** a user views a jobs or candidates table
- **THEN** rows have `border-b border-zinc-100` with `hover:bg-zinc-50`, header is `text-xs font-medium text-zinc-500 uppercase tracking-wider`, and no `table-zebra` striping is present

### Requirement: daisyUI off-ramp
The codebase SHALL NOT rely on daisyUI and SHALL NOT have any `daisyUI` dependency: `assets/css/app.css` SHALL NOT contain `@plugin "daisyui"` or `@plugin "daisyui/theme"`, and `assets/package.json` SHALL NOT list `daisyui`. The CSS bundle SHALL build and render identically without daisyUI.

#### Scenario: daisyUI is removed
- **WHEN** `mix assets.build` runs and the app is viewed in light and dark mode
- **THEN** no `@plugin "daisyui"` is present in `assets/css/app.css`, `assets/package.json` has no `daisyui` dependency, and all screens render identically to the pre-removal baseline (verified by `node scripts/screenshots.mjs` + `--axe`)

#### Scenario: Guardrail confirms no daisyUI classes remain
- **WHEN** `rg "daisyui|btn btn-primary|badge badge-|table-zebra" lib/treby_web assets/css/app.css assets/package.json` is run
- **THEN** no matches are found (except possibly in archived change docs)
