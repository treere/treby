## Context

After `2026-09-05-modern-saas-ui-refresh`, Treby's UI is fully on bespoke Tailwind (zinc tokens, `rounded-xl`, `shadow-sm`, `orange-600` CTA) via `TrebyWeb.DesignSystem.*` + `assets/css/app.css`. `daisyUI 5` (`@plugin "daisyui"` / `@plugin "daisyui/theme"`, `assets/package.json: daisyui ^5.0.35`) is still installed but no longer the styling contract — all live templates passed the guardrail (`rg "btn btn-primary|badge badge-|table-zebra" lib/treby_web --exclude-dir=design_system` is clean). The remaining daisyUI footprint is: two `@plugin` blocks that emit `base-100/200/300` etc, and the npm package itself (~150KB CSS). Removing it finalizes the single-token-system and satisfies `AGENTS.md: "Always manually write your own tailwind-based components instead of using daisyUI"`.

## Goals / Non-Goals

**Goals:**
- Delete `daisyUI` npm package and both `@plugin "daisyui*"` blocks from `assets/css/app.css` with zero visual change (Playwright pixel-identical).
- Prove the build (`mix assets.build`, `mix compile`) and runtime (light/dark, mobile) work without daisyUI.
- Shrink CSS bundle and eliminate the second theme system confusion.

**Non-Goals:**
- Any new visual design — strictly a dependency off-ramp.
- Changing `TrebyWeb.DesignSystem` APIs or live template markup beyond stray daisyUI class cleanup.
- Switching Tailwind version or adding new CSS tooling.

## Decisions

**Decision: Delete both `@plugin "daisyui"` and `@plugin "daisyui/theme"` blocks entirely, keep only custom tokens + `@custom-variant dark`.**
*Rationale:* The two theme blocks only set `--color-base-*`, `--radius-*`, `--depth`, `--noise`. The refresh already duplicated coverage with SaaS minimal values (`base-100 white`, `base-200 zinc-50` etc) but daisyUI still emits its own CSS. Deleting the blocks removes the dependency while the custom DS tokens remain. *Alternative:* keep blocks with `themes: false` as no-op — rejected: still pulls daisyUI CSS and invites drift.

**Decision: Remove npm package `daisyui` in the same commit, run `npm install --prefix assets`.**
*Rationale:* Atomic removal ensures no partial state where plugin references a missing package or vice versa. *Alternative:* two-step (CSS first, npm later) — more churn, same risk.

**Decision: Keep `data-theme` / `prefers-color-scheme` handling via the existing `@custom-variant dark` block, not via daisyUI's theme switch.**
*Rationale:* Already in `app.css:95` — `&:where([data-theme=dark])` + `@media (prefers-color-scheme: dark)`. No daisyUI needed for dark mode. Verified in refresh (dark screenshots `25-dark-mode.png` passed).

**Decision: Verify via exhaustive checks before merge — grep guardrail, `mix assets.build`, `mix test`, Playwright full run + `--axe`.**
*Rationale:* Any remaining `btn`/`badge`/`card`/`table` class would silently lose styling after removal. The grep + visual diff catches it.

## Risks / Trade-offs

- **Stray daisyUI class remains → unstyled element** → Mitigation: `rg "btn btn-|badge badge-|table-zebra|alert-info|rounded-box|rounded-btn" lib/treby_web` (plus broader `rg "\bbadge\b|btn-primary"`), full `node scripts/screenshots.mjs` before/after diff, manual spot-check of modals/dropdowns/toasts.
- **Dark mode breaks without daisyUI variables** → Mitigation: confirm `app.css` custom tokens cover `bg-zinc-800`/`zinc-900` etc and that `phx:set-theme` `localStorage "phx:theme"` still toggles `data-theme`; re-capture `25-dark-mode.png`.
- **`npm install` churn in `package-lock.json`** → Mitigation: commit lockfile in same commit, CI will run `npm ci --prefix assets`.
- **Bundle size reduction not visible** → Acceptable; benefit is conceptual cleanliness, not performance claim.

## Migration Plan

1. `rg` scan for any remaining daisyUI classes; fix if found.
2. Edit `assets/css/app.css`: delete `@plugin "daisyui" { themes: false; }` and both `@plugin "daisyui/theme"` blocks (light + dark). Keep `@import "tailwindcss"`, `@plugin "../vendor/heroicons"`, `@custom-variant` blocks, and `:root` DS tokens.
3. `npm uninstall daisyui --prefix assets` (or manual edit of `assets/package.json` + `npm install --prefix assets`).
4. `mix assets.build` + `mix compile --force` — must succeed with no `Can't resolve @plugin "daisyui"` error.
5. `node scripts/screenshots.mjs` (full run) + `--axe`; compare to post-refresh baseline — must be pixel-identical.
6. `mix test` + `mix precommit`.
7. `cd site && npm run build`.
8. Commit atomically. Rollback: `git revert` single commit, `npm install --prefix assets` restores daisyUI.

## Open Questions

- None — purely mechanical off-ramp. If any daisyUI utility proves still needed (none expected), we can re-add a minimal custom utility instead of re-adding the plugin.
