## Context

Settings is a single LiveView (`SettingsLive.Index`) rendering 14 cards in a flat grid, with each child page rendering its own full-page layout and a "Back to Settings" ghost button. The router groups all settings under the admin `live_session` (`RequireRole admin`), while the index template conditionally hides some cards — personal preferences are inconsistently gated. The top navigation compounds the noise with 8 text links (Jobs, Candidates, Assistant, Import, Interviews, Analytics, Message Queue, Settings) plus separate theme, language, and logout controls scattered in the header. Import is functionally a Candidates action; Message Queue is an operational queue (scheduled/sent/failed/cancelled) comparable to Audit Log in urgency, not a primary domain. As settings and nav items grow 1–2 at a time, both layers lose scannability.

Stakeholders: hiring managers / recruiters (daily users), admins (workspace config), members (personal scheduling + language). All pages use SaaS minimal tokens and must pass light + dark contrast.

## Goals / Non-Goals

**Goals:**
- Replace the flat settings grid with a sidebar grouped by domain (Option 2) — sticky left nav with 5 semantic groups, main pane on the right — without changing any URL.
- Trim the top bar from 8 to 5 primary text links (Jobs, Candidates, Interviews, Analytics, Assistant); relocate Import to Candidates and Message Queue to Settings → Communication.
- Unify scattered header utilities (theme, language, user, logout) into a single user dropdown; expose Settings as a gear icon for 1-click admin access.
- Make role and domain obvious at a glance (group headings + icons + admin badges + one-line subtitles) in both settings and top nav.
- Keep the change additive and low-risk: no DB, no new deps, no route renames, no auth model change beyond fixing the personal-settings gating bug; preserve deep links and bookmarks.

**Non-Goals:**
- No redesign of individual settings forms or queue/import flows (pipeline editor, scorecards, webhooks detail, CSV mapping/preview, queue tabs — all stay as-is).
- No new settings domain (no new preference keys or tables) beyond relocating existing entries.
- No full RBAC overhaul — only the minimal routing fix to let non-admins reach personal settings.
- No docs IA overhaul beyond updating menu paths/screenshots where labels shift.

## Decisions

### 1. Settings sidebar grouping — 5 sections, fixed order

**Decision:** Organization → Hiring Process → Communication → Scheduling → Privacy & System, in the order a new workspace is configured. 5 keeps each group to 2–4 items, scannable without scrolling on desktop. Message Queue joins Communication as its fourth item ("Message Queue" / "Scheduled Messages").

**Alternatives considered:** Alphabetical (no semantics), frequency-based (confusing for first-time admins), 3 sections (too coarse). Communication now holds Message Templates, Notifications, Webhooks, and Message Queue — all "how we talk / automate" — explicitly not a new Automation group to avoid proliferation.

**Company Availability ambiguity:** Show once under Organization as "Company hours (default)" with `Admin` badge, plus a muted link row under Scheduling ("Manage company defaults →") to the same route.

### 2. Top navigation — trimmed to 5 + utilities

**Decision:** Primary text links: **Jobs, Candidates, Interviews, Analytics, Assistant** — in that order (core hiring loop first, Assistant as utility at end). Remove **Import** and **Message Queue** from the top bar. Keep `Treby` brand, workspace switcher, notification bell.

**Alternatives considered:** Keep Assistant at center vs end — end wins because it is used less frequently than hiring loop. Keep Import as icon — rejected, it is not a domain. Keep Queue as top-level — rejected, urgency equals Audit Log, not Jobs.

### 3. Import relocation — to Candidates

**Decision:** Add a secondary `Import CSV` button (ghost/secondary variant, `hero-arrow-up-tray` icon) in `CandidatesLive.Index` header beside `+ Add Candidate`, visible in both populated and empty states. Empty state already has `Import from CSV`; the header button ensures discoverability when the list is non-empty. Keep route `/app/import` and breadcrumb `Candidates > Import`.

**Alternatives considered:** Tab inside Candidates — breaks deep link; keep top-nav Import as alias — defeats noise reduction.

### 4. Message Queue relocation — to Settings → Communication

**Decision:** Move from top nav to `Settings → Communication → Message Queue`. Keep route `/app/messages-queue` unchanged; sidebar link is the only entry. Optional polish: show a count badge for `failed` messages on the Communication group header or Settings gear (deferred to follow-up if not trivial).

**Alternatives considered:** New top-level "Automation" group for Webhooks + Queue — adds a section for 2 items; separate "Operations" group — same issue. Communication is the closest semantic home for "scheduled messages".

### 5. User menu + Settings gear — unified header utilities

**Decision:** Collapse `theme_toggle` + `locale_switcher` + `user name` + `Logout` into a single dropdown triggered by `👤 Name ▾` (avatar/name). Dropdown content: identity row (name, email, role badge), Theme segmented control (System/Light/Dark as 3 pills, reusing existing `theme_toggle` logic but rendered inside dropdown), Language (EN/IT), divider, Logout. **Settings** is a separate gear icon (`hero-cog-6-tooth`) next to the bell, visible only if `role == admin` — 1 click to settings. Mobile drawer mirrors the same grouping: primary nav + gear + user section at bottom.

**Alternatives considered:** B — everything including Settings inside user menu (2 clicks to settings, too deep for admin daily use). C — keep theme/language as standalone icons — keeps noise. Chosen hybrid (gear separate, theme+language+logout inside user menu) balances 1-click settings with noise reduction. Theme inside dropdown costs one extra click for theme switch — acceptable vs header clutter; keep `phx:set-theme` dispatch unchanged.

### 6. Hub stays at `/settings`; sidebar is a layout, not a new route tree

**Decision:** Introduce `settings_layout` function component (`lib/treby_web/components/settings_layout.ex` or `layouts.ex`) rendering the 2-column shell (sidebar + slot). `SettingsLive.Index` uses it for the hub; each child LiveView wraps its content with the same component, marking its item active. Hub main pane shows overview placeholder with group descriptions on desktop, stacked list on mobile.

**Alternatives considered:** Nested `live_session` with `:settings` layout — heavier, requires router restructuring.

### 7. Responsive behavior

**Decision:** `lg:flex` two-column; below `lg` sidebar collapses to full-width grouped list. Top bar below `xl` collapses to hamburger + drawer (existing) but with trimmed primary links and the new user section. Desktop sidebar is `sticky top-[4rem] self-start max-h-[calc(100vh-4rem)] overflow-y-auto`.

### 8. Role visibility — minimal fix

**Decision:** Admin sees all 5 groups (now 15 items with Queue). Member sees filtered view (Language, Calendar, My Availability, Data & Privacy personal) — Queue hidden, Communication group shows only allowed items; empty groups hidden. Callout "Some settings require admin" when filtered.

**Alternatives considered:** Split into `:settings_personal` vs `:settings_admin` live_sessions — follow-up if personal settings grow.

### 9. Active state + a11y

**Decision:** Active sidebar item uses `bg-zinc-100 text-zinc-900 font-medium` / `dark:bg-zinc-800` with `aria-current="page"` and stable `id` per link. Top-nav active uses same language. Gear icon uses same active treatment when on any `/settings` route (or distinct `bg-zinc-100 rounded-full`).

### 10. No URL changes

**Decision:** Keep every `~p"/app/..."` and `"/:tenant_slug/app/..."` path. Sidebar and Candidates header links use same sigils. Bookmarks remain valid.

## Risks / Trade-offs

- **Import discoverability drops when moved off top bar** → Mitigation: secondary button always visible in Candidates header, not only empty state; keep breadcrumb.
- **Message Queue less visible → failed messages missed** → Mitigation: optional badge count for failed on Communication header or Settings gear; otherwise rely on notification bell for failures (future hook). Accept 1 extra click as trade-off for top-bar clarity.
- **Theme inside dropdown adds 1 click for theme switch** → Mitigation: theme switch is infrequent; keep `phx:set-theme` dispatch; ensure dropdown stays open after switch or reopens trivially.
- **Sidebar + top-bar changes in one PR could feel big** → Mitigation: both are header/shell only, no form logic touched; child pages migration is mechanical (~3 lines each). Review as two commits (nav trim + sidebar) within one PR.
- **Mobile drawer must stay coherent with new grouping** → Mitigation: drawer mirrors desktop: primary nav (5 items), gear, user section with theme+language+logout.
- **Light/dark contrast for new icon + dropdown** → Mitigation: reuse `bg-white dark:bg-zinc-800`, `zinc-200/700` borders; run `node scripts/screenshots.mjs --axe`.

## Migration Plan

1. Add `SettingsLayout` component and static `settings_nav.ex` config (group → items with title, subtitle, icon, path, role, test id) including Message Queue under Communication.
2. Update `Layouts.app` top nav: trim to 5 primary links, remove Import and Message Queue entries, add gear icon (admin only) and unified user dropdown (theme + language + logout). Update mobile drawer accordingly.
3. Add `Import CSV` secondary button to `CandidatesLive.Index` header (beside Add Candidate), keep empty-state CTA.
4. Rewrite `SettingsLive.Index` to render the shell + grouped main pane (now with Queue).
5. Wrap each child `SettingsLive.*` plus `MessagesQueueLive.Index` render content with the same shell (active key set); keep secondary Back link.
6. (Optional) Split router if personal settings need non-admin session — no data migration.
7. Update screenshots + `site/features/*` menu paths if labels shift (e.g., Branding → Career Page, Message Queue path under Settings).
8. Run `mix precommit` + `mix test` (settings + navigation specs) + screenshots axe check.

Rollback: revert the shell + header components; no DB to roll back. Routes unchanged so rollback is safe.

## Open Questions

- Final label for Message Queue in Settings — "Message Queue" vs "Scheduled Messages" (proposal keeps "Message Queue" for continuity, could rename to "Scheduled Messages" for clarity).
- Should Settings gear also appear inside the user dropdown as duplicate for discoverability? (Proposal: no, keep single gear to avoid duplication, but could add muted link row in dropdown.)
- Filter input above sidebar: ship in v1 or defer? Default: defer.
- Assistant position in top bar — keep at end or move to secondary header? Default: end of primary nav.
