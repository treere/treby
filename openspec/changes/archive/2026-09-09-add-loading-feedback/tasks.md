## 1. Dead-view loading (login, registration, password reset, invites, candidate OTP)

- [x] 1.1 Add delegated `submit` handler in `assets/js/app.js` for `form[method="post"]:not([phx-submit])` — on submit, disable submit buttons, set `aria-busy="true"`, swap label via `phx-disable-with` / `data-loading-label`, and inject spinner (`hero-arrow-path motion-safe:animate-spin`). Ensure `phoenix_html` import remains.
- [x] 1.2 Update dead-view templates `lib/treby_web/controllers/session_html/new.html.heex`, `registration_html/new.html.heex`, `registration_html/verify.html.heex`, `registration_html/setup.html.heex`, `password_reset_html/new.html.heex`, `password_reset_html/edit.html.heex`, `invite_html/show.html.heex`, `candidate_otp/*` / `candidate_portal_live/verify.ex` dead forms to add `phx-disable-with` (localized via `gettext`) and spinner markup + `data-loading-label`.

## 2. LiveView forms — `phx-submit-loading` / `phx-click-loading`

- [x] 2.1 Update shared button usage or add helper so LiveView submit buttons use `phx-submit-loading:` classes: `phx-submit-loading:opacity-60 phx-submit-loading:pointer-events-none`, spinner `hidden phx-submit-loading:inline-flex motion-safe:animate-spin`, label swap `phx-submit-loading:hidden` / `hidden phx-submit-loading:inline`.
- [x] 2.2 Roll out to all LiveView `phx-submit` forms: `lib/treby_web/live/jobs_live/*`, `candidates_live/*`, `pipeline_live/*`, `settings_live/*`, `careers_live/apply.ex`, `candidate_portal_live/*`, `components/scorecard_form.ex`, etc. — ensure each submit button has the pending state. Also apply `phx-click-loading:` to mutating `phx-click` buttons where applicable (e.g., confirm dialogs).

## 3. Verification and a11y / themes

- [x] 3.1 Manual QA with network throttling (slow 3G): verify spinner + loading label appears on login and on 2–3 LiveView forms; verify double-click does not double-submit; check `motion-safe` and `aria-busy`/`disabled`.
- [x] 3.2 Verify light and dark themes (toggle via `Layouts.theme_toggle` / `data-theme`): ensure spinner contrast in both; run `node scripts/screenshots.mjs --axe` if available for a11y contrast.

## 4. Specs, docs, and final checks

- [x] 4.1 Run `mix precommit` and `mix test` (at least `test/treby_web/controllers/` and relevant LiveView tests); fix formatting/credo/dialyzer issues.
- [x] 4.2 Run `openspec validate --strict` and fix issues; ensure `openspec/specs/loading-feedback/spec.md`, `authentication/spec.md`, `password-reset/spec.md`, `form-submission/spec.md` (or delta specs) are coherent if archiving — otherwise keep change specs as source of truth until archive.
- [x] 4.3 (If user-facing docs needed) update `site/` feature pages and regenerate screenshots with `node scripts/screenshots.mjs`.
