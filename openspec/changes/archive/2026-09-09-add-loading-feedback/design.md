## Context

Treby has two submission models: dead-view POSTs (auth: login, registration, password reset, invite, candidate OTP) and LiveView `phx-submit` forms (~62 handlers). Neither currently shows pending feedback — login in particular appears frozen. Design-system primitives already exist (`Button` with `loading` prop, `Feedback.spinner`, `Pattern.loading_overlay`, Tailwind variants `phx-submit-loading`/`phx-click-loading` in `app.css`, `phoenix_html` + `topbar`) but are not wired to forms. The goal is to connect existing primitives with minimal, uniform changes across the app.

## Goals / Non-Goals

**Goals:**
- Immediate visual pending state on every user-initiated form submit / mutating click across the app.
- Prevent double-submit (`disabled` + `pointer-events-none`).
- Respect a11y (`aria-busy`/`disabled`, `motion-safe`), i18n (loading labels via `gettext`), and light/dark themes.
- Prefer CSS-only where LiveView already provides loading classes; use `phoenix_html`'s `phx-disable-with` for dead views; add only one tiny delegated JS fallback for dead-view spinner if needed.

**Non-Goals:**
- Full-page skeletons / route-level suspense.
- Changing auth to LiveView (keep dead POSTs).
- Introducing a new JS framework or global loading store.
- DB/schema changes.

## Decisions

**1. LiveView forms → Tailwind `phx-submit-loading:` / `phx-click-loading:` (CSS-only).**
- LiveView automatically adds `.phx-submit-loading` to the `<form>` while the `phx-submit` event is in flight and `.phx-click-loading` to clicked elements. The variants are already defined in `app.css`. Each submit button will use classes like `phx-submit-loading:opacity-60 phx-submit-loading:pointer-events-none` on the button and `hidden phx-submit-loading:inline-flex` on a spinner span, with label swap (`phx-submit-loading:hidden` vs `hidden phx-submit-loading:inline`). No per-form assigns or JS needed.
- Alternative considered: `Button` `loading` assign driven by `handle_event` state — rejected because it requires per-LiveView boilerplate and duplicates what LiveView already provides via CSS classes.

**2. Dead-view POSTs → `phx-disable-with` + CSS `:disabled` spinner.**
- `phoenix_html` (already imported) handles `phx-disable-with`: on submit it disables the button and swaps innerText. Add `data-loading-label` + delegated `submit` listener that injects a spinner span and `aria-busy="true"` for progressive enhancement, so even before `phoenix_html` swaps, visual feedback is instant. Works for login, registration (new/verify/setup), password reset (new/edit), invite show, candidate OTP/portal verify.
- Alternative considered: converting auth to LiveView — rejected as larger scope and unnecessary for loading UX.

**3. Reuse existing DesignSystem primitives, no new components.**
- `Button` already renders `hero-arrow-path animate-spin` when `loading={true}`; for LiveView CSS approach, use the same icon markup inline (`<.icon name="hero-arrow-path" class="size-4 motion-safe:animate-spin hidden phx-submit-loading:inline-flex" />`). For `loading_overlay`/`spinner`/`skeleton`, no change — they remain for page-level loads where already used.
- Alternative considered: new `LoadingButton` component — rejected to avoid API churn; a small helper function for loading label is enough if needed.

  **4. Single delegated JS in `assets/js/app.js` (no inline `<script>` in templates).**
  - One `document.addEventListener('submit', ...)` that for any non-GET dead form (`form:not([phx-submit])` where `method != "get"`) — covering `POST` and `DELETE`/`PUT`/`PATCH` via hidden `_method` — disables submit buttons, adds spinner, sets `aria-busy`. Keeps templates declarative and respects `AGENTS.md` rule against inline scripts. Implemented as `if (method === "get") return` to include logout `delete` forms.

## Risks / Trade-offs

- [Dead-view JS race with `phoenix_html`] → Mitigation: use `capture` phase listener, check `phx-disable-with` attribute; `phoenix_html` will still run and restore on bfcache — test with slow 3G via devtools.
- [i18n for loading labels] → Mitigation: loading labels come from `gettext` attributes (`data-loading-label={gettext("Signing in...")}` or `phx-disable-with={gettext("Signing in...")}`) so they stay translated.
- [Double-submit via Enter key] → Mitigation: disable all submit buttons in the form on first submit; also keep `disabled` on inputs via `phx-submit-loading:opacity-60` wrapper where sensible.
- [a11y / reduced motion] → Mitigation: `motion-safe:animate-spin`, `aria-busy`, `disabled` ensures screen readers announce busy state.

## Migration Plan

1. Add delegated submit handler to `app.js` + ensure `phoenix_html` import remains.
2. Update dead-view templates (session, registration×3, password_reset×2, invite, candidate OTP) to add `phx-disable-with` / `data-loading-label` and CSS spinner markup.
3. Update LiveView form templates (~20 files + shared button patterns) to add `phx-submit-loading:` / `phx-click-loading:` classes and spinner spans. Batch by file group (jobs, candidates, pipeline, settings, careers, etc.).
4. `mix precommit` + `mix test` (focus `test/treby_web/controllers/*` for auth flows); manual QA: throttle network to slow 3G, verify spinner appears on login and on a few LiveView forms in both light/dark.
5. Rebuild assets (`mix assets.build` if needed). No deployment migration; rollback is revert commit.

## Open Questions

- Exact loading label per action (e.g., "Signing in..." vs "Please wait...") — default to action-specific `gettext` where obvious, fallback to generic.
- Whether to also add `phx-click-loading` to non-form mutating buttons (e.g., pipeline drag, confirm dialogs) — include in rollout where `phx-click` is used for mutations.
