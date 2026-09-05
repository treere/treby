## 1. Pre-removal Verification

- [x] 1.1 Run guardrail grep `rg "daisyui|btn btn-primary|badge badge-|table-zebra" lib/treby_web assets --glob '!*.png'` and fix any remaining matches outside archived changes.
- [x] 1.2 Capture Playwright baseline `node scripts/screenshots.mjs --only 01-homepage,03-login-page,04-dashboard,05-jobs-list,07-pipeline-kanban,08-candidates-list,25-dark-mode` before removal.

## 2. Remove daisyUI from Build

- [x] 2.1 Edit `assets/css/app.css`: delete `@plugin "daisyui" { themes: false; }` and both `@plugin "daisyui/theme"` blocks (dark + light); keep `@import "tailwindcss"`, `@plugin "../vendor/heroicons"`, `@custom-variant dark`, and `:root` DS tokens.
- [x] 2.2 Remove `daisyui` from `assets/package.json` (and `assets/package-lock.json` via `npm install --prefix assets`); verify `mix tailwind.install --if-missing` not needed.
- [x] 2.3 Run `mix assets.build` and `mix compile --force`; verify no `@plugin "daisyui"` resolve error and CSS bundle shrinks.

## 3. Verification

- [x] 3.1 Run full `node scripts/screenshots.mjs` and `node scripts/screenshots.mjs --axe` (critical/serious must be 0); compare to baseline — pixel-identical.
- [x] 3.2 Run `mix test` (full suite) and fix any failures caused by missing daisyUI utilities.
- [x] 3.3 Manual QA: light/dark toggle, mobile drawer, modals/dropdowns/toasts render correctly without daisyUI.
- [x] 3.4 Rebuild docs site `cd site && npm run build`; verify no visual change.

## 4. Specs & Cleanup

- [x] 4.1 Sync `openspec/specs/design-system/spec.md` — accept `daisyUI off-ramp` delta (daisyUI SHALL NOT be present).
- [x] 4.2 Run `mix precommit` and `openspec validate --specs --strict` and fix all issues.
