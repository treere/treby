## 1. Restore primary color

- [x] 1.1 Add Tailwind v4 `@theme` block with `--color-primary` (+ `-content` companion) to `assets/css/app.css`, using the previously-shipped values
- [x] 1.2 Rebuild assets and confirm `bg-primary`/`text-primary` utilities are generated from sources

## 2. Prove the toggles

- [x] 2.1 Add LiveView test: admin flips each of the 3 toggles, state flips in DOM and persists to tenant settings
- [x] 2.2 Playwright check on the real page (Chromium, fresh profile): login → notifications → click toggle → assert track class flips → reload → assert persisted

## 3. Verify

- [x] 3.1 Re-capture notifications screenshot, confirm visible ON state and no other visual regressions
- [x] 3.2 `mix precommit` clean, full suite green
