## Why

The `modern-saas-ui-refresh` migrated all visual output to bespoke Tailwind (zinc neutrals, `rounded-xl`, `shadow-sm`) but left `daisyUI 5` installed (`assets/package.json: daisyui ^5.0.35`, `assets/css/app.css: @plugin "daisyui"` and `@plugin "daisyui/theme"`). The app no longer emits daisyUI class contracts (`btn`, `badge`, `card`, `table-zebra`) yet still pays the compile cost, bundle size, and confusion of a second theme system. Removing it finalizes the `AGENTS.md` rule ("never use daisyUI") and completes the `design-system` off-ramp.

## What Changes

- **BREAKING (visual contract):** Remove `daisyUI` and `@plugin "daisyui/theme"` from `assets/css/app.css`. The bespoke SaaS minimal tokens (page `zinc-50`/`zinc-900`, card `white`/`zinc-800`, `rounded-xl`, `shadow-sm`, `orange-600` CTA) become the sole source of truth; `daisyUI` CSS is no longer emitted.
- Remove `daisyUI` from `assets/package.json` and `package-lock.json`; run `npm install --prefix assets` and verify `mix assets.build` still succeeds without it.
- Remove any residual `daisyUI` theme variables (`--color-base-*`, `--radius-*`, `--depth`, `--noise`) that were kept for compat — replace with pure Tailwind/zinc where needed and keep `data-theme`/`prefers-color-scheme` support via the custom `@custom-variant dark` already in `app.css`.
- Verify no template or component still references daisyUI classes (`btn`, `badge`, `card`, `table`, `alert`, `dropdown`, etc.) — guardrail grep must stay clean outside `design_system/*` (now also clean inside).
- Re-run Playwright (`node scripts/screenshots.mjs --axe`), `mix test`, `mix precommit`, and `cd site && npm run build` to prove zero visual regression.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `design-system`: removes the "daisyUI MAY remain for compat" allowance; adds requirement that the CSS bundle SHALL build and render identically without any `daisyUI` plugin or package.

## Impact

- **Code**: `assets/css/app.css` (delete two `@plugin "daisyui*"` blocks, delete `daisyUI` theme variable declarations, keep custom tokens + `@custom-variant dark`), `assets/package.json`/`package-lock.json` (remove `daisyui`), `lib/treby_web/components/design_system/*` (no functional change, only verification that no daisyUI classes remain), `lib/treby_web/components/layouts.ex`/`core_components.ex` (verify no `alert`/`btn` remnants).
- **Dependencies**: `npm` — remove `daisyui`; `hex` — no change. Reduces CSS bundle size and `tailwindcss` compile time.
- **Migrations**: None.
- **Docs & Screenshots**: Re-run `node scripts/screenshots.mjs` after removal; `site/public/screenshots` must be pixel-identical (or improved) to post-refresh baseline.
- **Risk**: If any stray `btn`/`badge` class remains, that element will lose styling — mitigation is the grep guardrail + full Playwright run before merge.
