## Context

Treby is a Phoenix LiveView ATS with ~30 LiveViews, a VitePress docs site, and a Playwright screenshot pipeline (`scripts/screenshots.mjs`). The UI today is Tailwind v4 + daisyUI 5 (`assets/package.json: daisyui ^5.0.35`). `assets/css/app.css` defines two oklch themes (`light`/`dark`) with small radii and flat shadows, and `TrebyWeb.DesignSystem.*` is a thin wrapper over daisyUI `btn`/`badge`/`card` classes. `AGENTS.md` already directs contributors to write bespoke Tailwind components and avoid daisyUI — but the codebase contradicts that guidance, producing a generic admin look that users describe as "old / not modern."

Stakeholders: hiring managers/recruiters (trust + density), candidates (portal/career pages), admins. Constraints: LiveView (no SPA framework swap), Tailwind v4 import contract (`@import "tailwindcss" source(none)` + `@source`), Heroicons, Sortable.js for Kanban, no new heavy JS, light+dark theme must keep working, `site/` screenshots must be regenerable, accessibility (`axe-core --axe` in screenshots script) must not regress.

## Goals / Non-Goals

**Goals:**
- Establish a **Modern SaaS Minimal** visual language (Linear/Stripe/shadcn) as the default: zinc neutrals, one orange accent, `rounded-xl`/`rounded-lg`, hairline `border-zinc-200`, `shadow-sm`, `backdrop-blur` nav, generous whitespace, `Inter`.
- Make `assets/css/app.css` tokens + `TrebyWeb.DesignSystem.*` the single source of truth; off-ramp daisyUI class contract without breaking component APIs.
- Refresh high-traffic surfaces (app nav, landing, dashboard, tables, Kanban, forms, empty states) to the new language via DS only.
- Provide a visual regression + a11y guardrail (Playwright baseline + `axe`).

**Non-Goals:**
- Full rebrand (logo, naming, IA, route structure) — visuals only.
- Switching to Material 3, adding a component library (MUI, shadcn React), or introducing a CSS-in-JS / new build tool.
- Changing data models, APIs, or multi-tenant logic.
- Dark-mode redesign beyond token adaptation (same language, inverted surfaces).

## Decisions

**Decision: Bespoke Tailwind tokens over daisyUI — keep daisyUI installed temporarily, then remove.**
*Rationale:* daisyUI couples you to `btn`/`badge`/`card` semantics and its theme variables. Bespoke tokens give full control over the SaaS minimal palette and radii while satisfying `AGENTS.md`. Keep `@plugin "daisyui"` during migration for backward compat, then delete once DS components no longer emit daisyUI classes. *Alternative considered:* adopt Material 3 (`m3-tokens`) — rejected: too opinionated/pill-heavy for dense ATS tables and Kanban, feels Google-branded, heavier motion/elevation spec than needed. *Alternative considered:* adopt shadcn React — rejected: Treby is LiveView HEEx, not React.

**Decision: Token palette — `zinc` base, white cards, hairline borders, `shadow-sm`.**
- Light: page `zinc-50` (`oklch ~96-98%`), card `white`, border `zinc-200`, text `zinc-900` / `zinc-500` muted, primary `orange-600` for CTA only, `zinc-900` for secondary. Radii: `--radius-box 0.75rem (12px)`, `--radius-field 0.5rem`, `--radius-selector 0.5rem`. Shadows: `sm` default, `md` on hover, `depth:0` (no daisyUI depth). Dark: `zinc-900` page, `zinc-800` card, `zinc-700` border, same accent but desaturated.
*Rationale:* 2026 SaaS minimal is *neutral-first*. Orange remains brand but sparingly, improving hierarchy and Kanban scannability. *Alternative:* keep current orange `oklch(70% 0.213 47.604)` as dominant — rejected: washes out tables, low contrast on `base-200`.

**Decision: Navigation — translucent sticky header.**
`bg-white/80 backdrop-blur supports-[backdrop-filter]:bg-white/80 border-b border-zinc-200`, active state via `bg-zinc-100 text-zinc-900 rounded-md` not `border-b-2 border-primary`. Mobile drawer: same card language, `rounded-xl` sheet.
*Rationale:* Feels premium and keeps content dominant. *Alternative:* keep solid `bg-base-100 shadow` — retains dated flat header.

**Decision: Tables — remove `table-zebra`, use `hover:bg-zinc-50` + `border-b border-zinc-100` rows, header `text-xs font-medium text-zinc-500 uppercase tracking-wider`.**
*Rationale:* Zebra stripes add noise in dense ATS lists; hover + subtle dividers scan better. Aligns with Stripe/Linear tables.

**Decision: Kanban — columns as `bg-zinc-50 rounded-xl border border-zinc-200 p-3`, cards as `bg-white rounded-lg border shadow-sm hover:shadow-md transition`.**
*Rationale:* Creates depth without heavy elevation; drag affordance via `shadow-md` + `rotate-[1deg]`.

**Decision: Keep component APIs stable, change only class output.**
`Button` still `variant={primary|secondary|danger|ghost|outline} size={sm|md|lg} loading icon` — but maps to custom Tailwind (e.g., primary: `bg-zinc-900 text-white hover:bg-zinc-800` or `bg-orange-600` for main CTA variant, not `btn-primary`). Avoids churn in 30 LiveViews.
*Rationale:* Visual change without API break → low-risk rollout.

**Decision: Guardrail via grep/Credo + Playwright.**
Add a CI check `rg "bg-blue-600|bg-gray-500" lib/treby_web --glob '!design_system/*'` plus `node scripts/screenshots.mjs --axe` in CI. Baseline screenshots committed as before/after reference.
*Alternative:* visual regression service (Chromatic) — deferred, Playwright baseline is enough for now.

## Risks / Trade-offs

- **Visual regression across 30+ pages** → Mitigation: Playwright baseline before change, review diff per page (`--only` flag), sequential rollout by surface (tokens → DS → layouts → tables/Kanban).
- **Dark mode contrast drift** → Mitigation: define dark tokens alongside light in same `app.css` block, `axe` contrast check, manual review of `25-dark-mode.png`.
- **daisyUI removal breaks un-migrated screens** → Mitigation: keep daisyUI plugin during migration, grep for remaining `btn`/`badge`/`card` usage before deletion; feature-flag token switch if needed.
- **“Too minimal / too white” feedback** → Mitigation: keep orange accent for primary actions, add subtle `bg-zinc-50` page tint so cards pop; allow per-tenant branding override later.
- **Scope creep (re-theming every screen at once)** → Mitigation: tasks are sliced; MVP ships tokens+DS+nav+tables, follow-ups handle secondary screens.

## Migration Plan

1. **Baseline:** `mix ecto.reset && node scripts/screenshots.mjs` on `main`, archive screenshots as `baseline/`.
2. **Tokens:** Update `assets/css/app.css` theme blocks (colors, radii, shadows) — keep daisyUI variables for compat but shadow the new values.
3. **Design System:** Rewrite `TrebyWeb.DesignSystem.*` class mappings to bespoke Tailwind (Button/Badge/Card/Modal/Dropdown/Tabs/Avatar/Feedback/Pattern). No API changes.
4. **Layouts:** Update `TrebyWeb.Layouts.app` + portal header + mobile drawer to new nav language.
5. **Surfaces:** Migrate tables, Kanban, dashboard, landing, forms/empty states to DS + new tokens.
6. **Verify:** `mix precommit`, `mix test`, `node scripts/screenshots.mjs --axe`, manual light/dark + mobile check, regenerate `site/public/screenshots`, `cd site && npm run build`.
7. **Off-ramp:** Remove `@plugin "daisyui"` once no template emits daisyUI classes; delete guardrail exceptions.
8. **Rollback:** Revert single commit (purely presentational, no migrations); daisyUI re-enabled by reverting `app.css`.

## Open Questions

- Primary CTA color: keep Treby orange (`orange-600`) or shift to `zinc-900` with orange as secondary? **Proposal:** orange for *Create Job / Invite* primary, zinc-900 for secondary/destructive — validate in review.
- Should we introduce a `shadcn`-style `cn()` helper for class merging? Low priority; can use list syntax already in HEEx.
- Do we add a Storybook/DS preview page for visual QA, or rely on Playwright screenshots? **Leaning:** Playwright + `phoenix_storybook` already in `treby-sandbox` is enough.
