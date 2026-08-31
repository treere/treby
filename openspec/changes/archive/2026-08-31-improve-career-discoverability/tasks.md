## 1. LiveView / UI

- [x] 1.1 Add "Careers" link to `HomeLive` header (desktop + mobile drawer) pointing to `/careers` with gettext and unique DOM id `home-careers-link` — verify via `mix test` or manual render.
- [x] 1.2 Add "Careers" link to `HomeLive` footer alongside existing footer links.
- [x] 1.3 Ensure responsive behavior: header link collapses gracefully on <640px (reuse existing responsive classes).

## 2. Tests

- [x] 2.1 Add/extend LiveView test for `HomeLive` asserting header and footer contain link to `/careers` via `has_element?`.
- [x] 2.2 Run `mix test test/treby_web/live/home_live_test.exs` (or create if missing) and fix failures.

## 3. Specs + Docs

- [x] 3.1 Update main specs at `openspec/specs/landing-page/spec.md` and `openspec/specs/public-job-board/spec.md` with Purpose/Requirements and Scenario WHEN/THEN (already captured as delta — sync on archive).
- [x] 3.2 Sync `site/` user manual if it documents landing page navigation (add "Careers" to menu path description) and regenerate screenshots with `node scripts/screenshots.mjs`.
- [x] 3.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
