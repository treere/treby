## Why

Currently the team app and the candidate portal rely on clicking the brand/logo to return home — there is no explicit "Home" / "Dashboard" button. This is undiscoverable, hurts accessibility and mobile usability, and creates inconsistency between the two portals. The candidate portal also shows applications as a flat list with minimal context, so candidates cannot quickly see which companies and positions they applied to, whether they have unread messages, or key company information for each application.

## What Changes

- Add an explicit **Home** navigation item to the authenticated team app header and mobile drawer, alongside Jobs / Candidates / Interviews / Analytics / Assistant. The brand logo keeps its existing behavior.
- Add an explicit **Dashboard** (Home) navigation item to the candidate portal header and mobile drawer, alongside Messages / Schedule / Settings. The tenant brand keeps its existing behavior.
- Redesign the candidate portal dashboard (`/:tenant_slug/portal`) around information clarity:
  - Summary header with counts: total applications, unread messages, pending actions.
  - Applications grouped or clearly annotated by company (tenant name/logo) and position, each card showing: job title, company name/logo, location/type badges when available, current stage with human-readable label and colored badge, applied date, unread message indicator + preview, and a link to the company/position context.
  - Quick company info affordance per application (name, logo, short description, help/contact when configured) without leaving the portal.
  - Preserve existing empty state and detail/timeline व्यवहार; improve card density and mobile layout.
- Ensure active-link highlighting, keyboard and screen-reader accessibility, and 44px touch targets for the new nav items.
- Fix settings layout scrolling: the Settings hub and all child pages (`/app/settings/*`) SHALL scroll as a single page. Remove the independent scroll container on the sidebar/main pane so there is only one vertical scrollbar. Tapping/clicking a sidebar section SHALL bring the content into view (auto-scroll to the main pane) on both mobile and desktop — including when the user is scrolled down the page.

## Capabilities

### New Capabilities

- _None — this change enhances existing capabilities._

### Modified Capabilities

- `app-navigation`: add explicit Home entry point to team app navigation (desktop + mobile), update active-link rules and nav ordering.
- `candidate-portal-dashboard`: restructure portal dashboard and navigation for candidate visibility — explicit Dashboard nav, summary stats, company/position grouping, unread message visibility, and quick company information.
- `settings-navigation`: remove dual-scroll (sidebar + content) in favor of single-page scroll and ensure mobile section navigation auto-scrolls to visible content.

## Impact

- **Code**: `lib/treby_web/components/layouts.ex` (app + candidate_portal layouts), `lib/treby_web/live/candidate_portal_live/index.ex` (+ `messages.ex` if shared nav), `lib/treby_web/components/settings_layout.ex` + `lib/treby_web/live/settings_live/*` (single-page scroll + mobile scroll-into-view), `lib/treby_web/router.ex` (if route alias for `/portal` dashboard clarity), `lib/treby/candidate_portal.ex` / `lib/treby/pipeline.ex` (read-only queries for counts/unread).
- **APIs/Routes**: No breaking route changes; `/:tenant_slug/portal` remains dashboard, `/:tenant_slug/portal/messages` stays messages. New nav links are additive.
- **Dependencies**: None new. Tailwind 4 + existing design system only.
- **Migrations**: None expected (uses existing `applications`, `conversations`, `messages`, `jobs`, `tenants` data).
- **Docs/Screenshots**: Update `site/` feature pages if they show navigation; regenerate `node scripts/screenshots.mjs` after.
