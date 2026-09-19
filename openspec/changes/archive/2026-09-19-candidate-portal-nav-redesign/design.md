## Context

The team app (`Layouts.app`) and the candidate portal (`Layouts.candidate_portal`) both use a sticky translucent SaaS-minimal header. Today the primary way back to the home/dashboard is clicking the brand text ("Treby" or tenant name). There is no explicit labelled navigation item for Home/Dashboard, so the action is undiscoverable — especially on mobile and for keyboard/screen-reader users.

The candidate portal (`/:tenant_slug/portal` and sub-routes `/messages`, `/schedule`, `/settings`) currently has a minimal header with links to Messages / Schedule / Settings only. The dashboard (`CandidatePortalLive.Index`) lists applications as a flat stack with job title + description + stage badge. It lacks summary context (how many applications, unread messages, pending actions), explicit company affordance (logo/name/description/help contact), and per-card unread indicators. Messages and schedule are separate pages, so the candidate must navigate to discover unread items.

The Settings hub (`/app/settings` + children like `/app/settings/pipeline`, `/app/settings/team`, etc.) is rendered via `TrebyWeb.SettingsLayout.settings_shell` as a two-column layout `flex flex-col lg:flex-row` with a sidebar card that on desktop is `lg:sticky lg:top-20 lg:max-h-[calc(100vh-6rem)] lg:overflow-y-auto` — i.e., an inner scroll container independent from the page scroll. On mobile the layout stacks (`flex-col`) so the sidebar sits on top of the content. Navigating to a child page therefore leaves the viewport at the top of the sidebar; the user must manually scroll past the entire grouped list to reach the content. Having two scroll contexts on desktop is also confusing.

Stakeholders: candidates (primary), recruiters viewing candidate experience, admins configuring branding/support contact. Constraints: no new dependencies, Elixir/Phoenix/LiveView/Tailwind only, tenant isolation must hold, `site/` docs must stay user-facing and English-only, screenshots must be regenerated after UI changes.

## Goals / Non-Goals

**Goals:**
- Make "go home" explicit and accessible in both the team app and the candidate portal (desktop + mobile), without removing the existing brand link.
- Make the candidate portal an informative overview: at a glance see which positions at which company the candidate applied to, unread message count/preview, pending actions, and quick company information.
- Keep the change additive, style-consistent (SaaS minimal tokens, `rounded-xl`/`shadow-sm`, `zinc-*`/`orange-600` CTA, `dark:` variants), and fully tenant-scoped.

**Non-Goals:**
- Cross-tenant aggregation of applications for a single candidate email (candidate `tenant_id` remains authoritative; "which companies" is shown as the tenant/company attached to each application card and summarized in the header — no cross-tenant query or identity merge).
- Chat redesign, scheduling flow redesign, or email/notification content changes beyond surfacing counts and previews already available via `CandidatePortal` and `Pipeline` contexts.
- New database tables or columns, new external services, or a full information-architecture overhaul of the team app.

## Decisions

**1. Explicit Home nav item (team) + Dashboard nav item (portal) — additive, first in order**
- Team header: add `Home` as the first link in the desktop `xl:flex` row and mobile drawer, pointing to `/:tenant_slug/app` (or `/app` when tenant missing). Keep the existing brand `.link` to the same destination. Mark active with the existing pill style `bg-zinc-100 text-zinc-900 rounded-md font-medium` / `dark:bg-zinc-800`. Add `id="nav-home"` and `data-nav` attribute, with `aria-current="page"` when active. Icon `hero-home` on mobile, text-only on desktop to match current nav density.
- Portal header: add `Dashboard` as the first link in both `sm:flex` and the `sm:hidden` drawer, pointing to `/:tenant_slug/portal`. Same active pill treatment. Brand link remains.
- Alternative considered: replace brand link with Home button — rejected; breaks learned behavior and accessibility expectations (brand → home is standard, but should not be the *only* way).
- Alternative considered: breadcrumbs — rejected; overkill for portals with flat navigation.

**2. Portal dashboard information architecture — summary strip + enriched cards**
- Above the applications list, render a compact summary strip (three stats): `Applications`, `Unread messages`, `Pending actions`. Values derived from existing read paths: `Pipeline.list_applications_for_candidate/2`, `CandidatePortal.list_conversations_for_candidate/2` (count where last message is `recruiter` and not locally dismissed — or dedicated unread count if available), and `candidate_pending_action/2` per application. No new writes; counts computed on mount and refreshed on `{:conversation_updated, _}` broadcast.
- Each application card keeps being a `phx-click="select_application"` target, but content expands: job title + company name/logo (from `current_tenant` + `tenant.settings["logo_url"]`), location/type badges when `job` carries them, human stage badge, applied date, unread indicator (dot + "Unread" badge when latest recruiter message is unread), and a one-line message preview. Below the list, a small "Company" affordance: tenant name, logo, short description (`tenant.settings["company_description"]` if present), and `Need help? Contact …` when `support_email`/`contact_email` is configured — reusing the same rule as the public apply flow (`public-job-board` spec).
- Detail pane already shows timeline/progress/action/conversation — keep as-is, but ensure it is reachable from both the card click and an explicit "View details" link for accessibility.
- Alternative considered: grouped accordion by company — unnecessary while a candidate belongs to a single tenant; would add complexity with no current benefit. If multi-tenant candidates appear later, grouping can be added without breaking this card layout.
- Alternative considered: separate inbox icon in portal header — deferred; the summary strip plus per-card unread is cheaper and avoids header clutter.

**3. Styling and behavior reuse**
- Reuse existing header translucency, pill hover `hover:bg-zinc-50`, focus rings, and dark-mode tokens from `layouts.ex`. No new CSS file. Ensure `[data-theme="dark"]` parity and verify with `node scripts/screenshots.mjs --axe` for contrast.
- Follow tenant isolation: all dashboard queries filter by `(tenant_id, candidate_id)`; tenant-slug mismatch already redirects in `mount/3` — keep that behavior for the new counts as well.

**4. Settings single-page scroll + auto-scroll to content on section navigation**
- Single scroll: remove the independent scroll container from the settings sidebar (`lg:max-h-[calc(100vh-6rem)] lg:overflow-y-auto`). Keep `lg:sticky lg:top-20` only (no max-height/overflow) so the whole page shares one vertical scrollbar. The sidebar sticks while the page scrolls, but does not introduce its own scrollbar.
- Auto-scroll: keep the stacked grouped list on top on mobile, and the sticky sidebar on desktop, but ensure navigation to a child route always brings content into view — whether on mobile or desktop when the user is scrolled down. Add `id="settings-main"` to the main pane and a tiny colocated hook (`:type={Phoenix.LiveView.ColocatedHook}` with `".SettingsScroll"`, no external asset) that on `mounted`/`updated`, when `active_key != nil`, calls `document.getElementById("settings-main")?.scrollIntoView({behavior: "smooth", block: "start"})`. On the hub (`/app/settings`, `active_key == nil`) do not scroll so the grouped list remains at top. Alternative considered: limit to `< lg` — rejected per request; desktop users at the bottom of a long page need the same behavior. Alternative considered: collapsing the sidebar behind a disclosure — rejected for this change to keep the established list pattern; scroll achieves the "go down where section is visible" requirement with minimal change. Alternative considered: hash-anchor `#settings-main` on each link — would work but pollutes URLs and history; JS scroll is cleaner.
- No new dependency; one colocated hook is the laziest that actually works. If later a collapsed sidebar is desired, it can replace the scroll with a drawer toggle without touching the single-scroll fix.

**5. Scope discipline (ponytail ladder)**
- No new dependency, no new DB migration. All data already exposed by `Pipeline` and `CandidatePortal`. The laziest solution that satisfies visibility is enriched reads + a few extra nav links + removing one CSS scroll container + one small colocated scroll hook.

## Risks / Trade-offs

- **Unread semantics without a persisted read marker** → Mitigation: derive unread as "last message sender is recruiter" per conversation and show preview + highlight; treat as informational, not as a formal inbox read-state. If a proper `read_at` marker is added later, the same badge slot upgrades.
- **Company info sparse when tenant not configured** → Mitigation: render only what exists (name always, logo when `logo_url`, description when `company_description` / `settings` key present, help block only when email present). No fallback placeholder email.
- **Nav crowding on narrow desktop** → Mitigation: keep Home text short, reuse existing `xl:` breakpoint, and verify header wraps without overflow at 1280px and 1024px.
- **Settings sticky without inner scroll may make long sidebars overflow viewport** → Mitigation: sidebar content is ~5 groups × 2–4 items; max height stays within viewport at 1280px+. On shorter viewports the sidebar simply scrolls with the page — which is the requested behavior (single scrollbar). No fixed max-height avoids the dual-scroll confusion.
- **Auto-scroll could be jarring if user intentionally wanted to see sidebar** → Mitigation: only scroll on navigation to a non-hub child (`active_key != nil`); hub (`/app/settings`) stays at top so the grouped list remains visible. Smooth scroll preserves orientation.
- **Screenshot/translation churn** → Mitigation: add `gettext` for new labels ("Home", "Dashboard", "Applications", "Unread", "Pending action", "Company"), update `priv/gettext` extraction, and regenerate screenshots.

## Migration Plan

1. Update `lib/treby_web/components/layouts.ex`: add Home to `.app` nav and Dashboard to `.candidate_portal` nav (desktop + mobile drawer) with active highlighting and `data-nav` attributes.
2. Update `lib/treby_web/live/candidate_portal_live/index.ex`: compute summary assigns (`@stats`), enrich card assigns with unread preview + company context, render summary strip and enriched cards.
3. Update `lib/treby_web/components/settings_layout.ex`: drop `lg:max-h-[calc(100vh-6rem)] lg:overflow-y-auto` from sidebar, add `id="settings-main"` to main pane, add colocated `.SettingsScroll` hook for auto-scroll to content on child pages (all viewports).
4. Add/adjust gettext entries for new labels.
5. Run `mix gettext.extract` / `mix gettext.merge` (if project uses merge), `mix precommit`, and `node scripts/screenshots.mjs` to refresh docs screenshots. No DB migration.
6. Rollback: revert the layout/LiveView commits; no data migration to undo.

## Open Questions

- Should "which companies I applied to" eventually aggregate across tenants for a single email, or does tenant-scoped visibility remain the product stance? Current decision: tenant-scoped, card shows single company explicitly; cross-tenant aggregation deferred.
- Formal unread marker (persisted per candidate per conversation) would make the unread badge exact — worth adding later if candidates report confusion.
- Do we also want a small persistent unread badge on the portal header (like `notification_bell`) linking to Messages? Held as follow-up; summary strip covers v1.
