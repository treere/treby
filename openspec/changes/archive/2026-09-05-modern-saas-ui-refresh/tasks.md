## 1. Baseline & Guardrail Setup

- [x] 1.1 Capture Playwright baseline: `mix ecto.reset && node scripts/screenshots.mjs` on current `main`; archive `site/public/screenshots` to `baseline/` for diff.
- [x] 1.2 Add CI guardrail grep that fails on hardcoded `bg-blue-600`, `bg-gray-500`, `btn btn-primary`, `badge badge-`, `table-zebra` outside `lib/treby_web/components/design_system/*`; document in `AGENTS.md`.

## 2. Design Tokens — assets/css/app.css

- [x] 2.1 Update light theme tokens to SaaS minimal: page `zinc-50` / card `white` / border `zinc-200` / text `zinc-900`+`zinc-500`, radii `--radius-box 0.75rem` / `--radius-field 0.5rem`, shadows `sm` default; keep dual `light`/`dark` blocks.
- [x] 2.2 Update dark theme tokens: page `zinc-900` / card `zinc-800` / border `zinc-700` / content `zinc-100`, adapted `--ds-shadow-*`; verify `prefers-color-scheme` fallback still works.
- [x] 2.3 Remove reliance on daisyUI theme vars as source of truth (`--color-base-*`, `--depth:1` remain only for compat); verify `mix assets.build` still passes with `@plugin "daisyui"` present.

## 3. Design System Primitives — lib/treby_web/components/design_system/*

- [x] 3.1 Rewrite `DesignSystem.Button` class mapping to bespoke Tailwind (primary `bg-zinc-900`/`bg-orange-600`, secondary `bg-white border-zinc-200`, danger `bg-red-600`, ghost/outline neutral) with `rounded-lg shadow-sm`; keep `variant/size/loading/icon` + `href/navigate/patch` API.
- [x] 3.2 Rewrite `DesignSystem.Badge` to `inline-flex rounded-full border text-xs font-medium` per variant (no `badge badge-*`).
- [x] 3.3 Rewrite `DesignSystem.Card` to `bg-white rounded-xl border border-zinc-200 shadow-sm` (+ header `border-b border-zinc-100`, footer) with `bordered/elevated/flat` variants mapped to SaaS minimal.
- [x] 3.4 Rewrite `DesignSystem.Modal` / `Dropdown` / `Tabs` / `Avatar` / `Feedback` (Spinner/Skeleton/Toast) to `rounded-xl shadow-xl` language and theme-aware surfaces.
- [x] 3.5 Rewrite `DesignSystem.Pattern` (ConfirmDialog/PageHeader/EmptyState/FilterBar/FormSection/LoadingOverlay) to SaaS minimal; `PageHeader` uses `border-b border-zinc-100` breadcrumbs style.
- [x] 3.6 Update `TrebyWeb.DesignSystem` helpers (`variant_classes/1`, `badge_classes/1`, `size_classes/1`) to new class maps; ensure `mix compile` no warnings.

## 4. Layouts & Navigation — lib/treby_web/components/layouts.ex

- [x] 4.1 Restyle `Layouts.app` desktop nav to translucent `bg-white/80 backdrop-blur border-b border-zinc-200`, link pills `rounded-md` with `hover:bg-zinc-50`, active `bg-zinc-100 text-zinc-900`.
- [x] 4.2 Restyle mobile drawer + portal header to same language (`rounded-xl` sheet, `bg-white border-zinc-200`); verify `sm:hidden` / `phx-click` JS toggles still work.
- [x] 4.3 Update outer page wrapper from `bg-base-200` to `bg-zinc-50` (light) / `bg-zinc-900` (dark); verify flash group + theme toggle still render.

## 5. Surface Polish — lib/treby_web/live/**/* & controllers

- [x] 5.1 Migrate tables (`CoreComponents.table` + live index pages) from `table-zebra` to `hover:bg-zinc-50` + `border-b border-zinc-100` rows, header `text-xs font-medium text-zinc-500 uppercase tracking-wider`.
- [x] 5.2 Restyle pipeline Kanban (`pipeline_live`) columns `bg-zinc-50 rounded-xl border border-zinc-200` and cards `bg-white rounded-lg border shadow-sm hover:shadow-md transition`.
- [x] 5.3 Polish dashboard, jobs, candidates, interviews, analytics, settings forms and empty states to use DS + new tokens (no ad-hoc markup).
- [x] 5.4 Polish landing + auth + career pages + candidate portal to SaaS minimal cards/CTAs.

## 6. Tests & Verification

- [x] 6.1 Run existing LiveView tests for navigation, pipeline, candidates, jobs; fix selectors where class changes break `has_element?` assertions (prefer DOM IDs over class strings).
- [x] 6.2 Run `node scripts/screenshots.mjs --axe` and fix any axe `critical`/`serious` contrast violations introduced by new zones.
- [x] 6.3 Manual light/dark + mobile viewport QA (1280×900 baseline + <640px), verify no `base-100/200` grey bleed remains.

## 7. Docs, Specs & Cleanup

- [x] 7.1 Sync `openspec/specs/design-system/spec.md`, `openspec/specs/app-navigation/spec.md`, `openspec/specs/landing-page/spec.md` — accept deltas from this change.
- [x] 7.2 Regenerate screenshots: `node scripts/screenshots.mjs` and rebuild docs site `cd site && npm run build`; verify `site/public/screenshots` updated.
- [x] 7.3 Remove `@plugin "daisyui"` from `assets/css/app.css` once no template emits daisyUI classes; verify `mix assets.build` + screenshots still pass; otherwise keep for follow-up.
- [x] 7.4 Run `mix precommit` and `openspec validate --strict` and fix all issues.
