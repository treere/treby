## Why

Treby's current UI is built on daisyUI 5 with small radii (`0.25rem`), flat shadows (`depth:1`), and generic `base-100/200` surfaces. It is functional but visually anonymous — the same palette, spacing, and card/table styles as any admin template. Users report it feels "old" and not modern. In 2026 the B2B SaaS standard has moved to a muted, minimal aesthetic (Linear / Stripe / Vercel / shadcn): zinc neutrals, one accent, `rounded-xl`, hairline borders, `shadow-sm`, generous whitespace, and `Inter`. Staying on the current daisyUI defaults undermines trust for a hiring product and conflicts with `AGENTS.md` which already mandates bespoke Tailwind components over daisyUI.

## What Changes

- Replace daisyUI as the visual source of truth with a bespoke **Modern SaaS Minimal** design system. Keep Tailwind v4 + oklch but remove reliance on `btn`/`badge`/`card` daisyUI classes as the styling contract. `assets/css/app.css` tokens become the single source for color, radius, shadow, and spacing.
- Refresh tokens: page background `zinc-50`, card `white` + `border-zinc-200` + `shadow-sm`, radii `12-16px` (box) / `8px` (field), compact neutral palette with orange-600 reserved for primary CTA only. Keep `Inter`/`JetBrains Mono` and theme-aware dark mode.
- Redesign primitives in `TrebyWeb.DesignSystem.*` (Button, Badge, Card, Modal, Dropdown, Tabs, Avatar, Feedback, Pattern) to the new visual language — no breaking API, only visual output changes.
- Update `TrebyWeb.Layouts.app` navigation: translucent `bg-white/80 backdrop-blur`, `border-b`, active state via subtle background not heavy border, improved density and hover states for desktop + mobile drawer.
- Polish high-impact surfaces: landing page, dashboard, jobs/candidates tables (remove `table-zebra`, use `hover:bg-zinc-50`), pipeline Kanban columns, settings/forms, and empty states — all via DS components, no ad-hoc markup.
- Establish a guardrail (grep/Credo rule) preventing reintroduction of hardcoded `bg-blue-600`/`bg-gray-500` styles outside `design_system/*`.
- Regenerate VitePress screenshots (`site/public/screenshots`) and update docs after the visual change.

## Capabilities

### New Capabilities
<!-- none — this is a visual evolution of existing capabilities -->

### Modified Capabilities
- `design-system`: tokens, component visuals, and migration requirements change from daisyUI-backed to bespoke Tailwind SaaS minimal; adds radius/shadow/background token requirements and removes daisyUI class contract.
- `app-navigation`: nav bar visual spec changes from flat `bg-base-100 shadow` to translucent/blur + border + refined active/hover states.
- `landing-page`: hero/feature/footer visual spec changes to align with new SaaS minimal language (neutral page, white cards, refined CTA).

## Impact

- **Code**: `assets/css/app.css` (theme tokens — colors, radii, shadows, light/dark), `lib/treby_web/components/design_system/*` (Button, Badge, Card, Modal, Dropdown, Tabs, Avatar, Feedback, Pattern + `design_system.ex`), `lib/treby_web/components/layouts.ex` (app nav + mobile drawer + portal header), `lib/treby_web/components/core_components.ex` (table/list/header flash alignment), `lib/treby_web/live/**/*` and `lib/treby_web/controllers/**/*` (template class adjustments to use DS), `assets/js/*` (no JS changes expected).
- **Dependencies**: No new npm/hex deps. Potential to *remove* reliance on `daisyui` theme plugin over time (kept temporarily for compatibility, then off-ramped). `heroicons` and `sortablejs` unchanged.
- **Migrations**: None — purely presentational.
- **Docs & Screenshots**: `site/` feature pages remain content-identical but screenshots regenerated via `node scripts/screenshots.mjs`; `site/.vitepress/dist` rebuilt.
- **Risk**: Visual regression across ~30+ pages; requires Playwright screenshot baseline + axe a11y re-check (`--axe`).
