## Why

Users currently see no visual feedback during form submissions and other waits (login, registration, password reset, and many LiveView forms). The page appears frozen, causing confusion and double-submits. Immediate, consistent loading feedback is needed to reassure users that their action is being processed.

## What Changes

- **Dead views (full POST: login, registration, password reset, invite acceptance, candidate OTP)**: add `phx-disable-with` (via `phoenix_html`) and CSS-driven spinner/disable on submit buttons so the button shows a spinning indicator and localized "Signing in..." / "Sending..." text while the POST is in flight. One lightweight delegated JS fallback ensures the same UX even before `phoenix_html` swaps text (progressive enhancement).
- **LiveView forms (62 `phx-submit` handlers across jobs, candidates, pipeline, settings, career apply, etc.)**: wire existing Tailwind variants `phx-submit-loading:` / `phx-click-loading:` (already defined in `assets/css/app.css`) to dim/disable the submit button and swap label ↔ spinner+loading label purely via CSS — no per-form JS state.
- **Global polish**: ensure `topbar` remains for LiveView navigations; loading states respect `motion-safe`, `disabled`, `aria-busy`, and both light/dark themes. Guard against double-submit via `pointer-events-none` + `disabled`.
- No breaking API or schema changes.

## Capabilities

### New Capabilities
- `loading-feedback`: Consistent loading/pending UI for all user-initiated waits — button spinner + localized loading label on dead-view POSTs and `phx-submit-loading` CSS states on LiveView forms; prevents double-submit and meets a11y expectations.

### Modified Capabilities
- `authentication`: Requirement to show loading feedback on sign-in is added (was previously silent wait).
- `password-reset`: Requirement to show loading feedback on reset request/submit.
- `form-submission`: General requirement that every form submission provides immediate visual pending state.

## Impact

- Affected templates: `lib/treby_web/controllers/session_html/*`, `registration_html/*`, `password_reset_html/*`, `invite_html/*`, `candidate_otp/*`, and ~20 LiveView templates under `lib/treby_web/live/**/*` plus `lib/treby_web/components/design_system/button.ex` (optional helper).
- Assets: `assets/css/app.css` (variants already present, no change), `assets/js/app.js` (small delegated submit handler for dead views + ensure `phoenix_html` import is active). No new dependencies.
- No migrations. No config/env changes. Docs in `site/` updated only if user-facing behavior warrants it (likely not).
