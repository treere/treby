## Context

Playwright exploration showed the landing page (`/`, `HomeLive`) exposes only team-oriented CTAs ("Get started", "Log in") and no path to public job boards. Tenant career pages (`/:tenant_slug/careers`, `CareersLive.Index`) and the global board (`/careers`, `GlobalIndex`) are reachable only via direct URL. Analytics-free but funnel-critical: anonymous candidates arriving via marketing site cannot discover openings without being given a slug.

Current `HomeLive` renders a custom header with locale/theme toggles, logo, and two auth links. `Layouts` module holds shared nav for authenticated app but not for public root.

## Goals / Non-Goals

**Goals:**
- Make open positions discoverable in one click from `/`.
- Keep public nav minimal and consistent across desktop/mobile.
- Preserve existing landing-page conversion focus (team signup).

**Non-Goals:**
- Tenant-scoped homepage (e.g., `/:tenant_slug` landing) — keep `/careers` global.
- SEO sitemap / structured data — separate change.
- Changing career-page board logic or job visibility rules.

## Decisions

- **Add "Careers" to HomeLive header (alongside Log in / Get started):** `HomeLive` owns the public header, not `Layouts.app`. Keeps change isolated. Alternative: shared public layout — rejected as over-engineer for single link.
- **Label "Open positions" / "Careers" (i18n via gettext):** Use `gettext("Careers")` with IT translation "Posizioni aperte" already in `priv/gettext`. Link target `/careers`. Alternative tenant-aware `/acme/careers` not suitable for global nav.
- **Footer link:** Duplicate entry in footer for scroll-depth users; no extra logic.
- **No auth-gate:** Link visible to both anonymous and logged-in visitors (logged-in users already have app nav; extra link is harmless).
- **Styling:** Reuse existing header classes (`text-sm/6 font-semibold`) to avoid visual regression; active state via `data-nav` not needed for public root.

## Risks / Trade-offs

- [Risk] Header crowding on small screens → Mitigation: hide label behind hamburger or use short label "Jobs" on `sm` breakpoint; existing `HomeLive` already has responsive header.
- [Risk] Translation missing → Mitigation: add `msgid "Careers"` to both `en` and `it` PO files; fallback to English.

## Migration Plan

- No migration. Deploy as static template change. Rollback = revert `home_live.ex`.
- Verify with `mix test test/treby_web/live/home_live_test.exs` (if exists) or manual Playwright screenshot `node scripts/screenshots.mjs`.

## Open Questions

- Should the header link be tenant-aware when a `tenant_slug` cookie/session is present? Deferred — keep global for now.
