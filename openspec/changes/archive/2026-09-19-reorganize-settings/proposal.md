## Why

The Settings hub (`/app/settings`) renders 14 cards in a flat 2-column grid with no semantic grouping, mixing personal preferences (Language, Calendar, My Availability) with workspace admin configuration (Pipeline, Team, Webhooks). The top navigation adds noise with 8 text links (Jobs, Candidates, Assistant, Import, Interviews, Analytics, Message Queue, Settings) plus scattered theme/language/logout controls. Import is an action of Candidates, not a top-level domain; Message Queue is an operational queue with the same urgency as Audit Log, not a primary navigation item. A grouped sidebar for Settings plus a trimmed top bar with a unified user menu makes both layers scannable and scalable.

## What Changes

- **Settings — sidebar grouped by domain (Option 2, directly):** Replace the flat grid in `SettingsLive.Index` with a sticky left nav + detail area grouped by semantic domain. Groups (5):
  - **Organization** — Team, Branding (Career Page), Company Availability (default hours)
  - **Hiring Process** — Pipeline + Stages, Custom Fields, Scorecard Templates
  - **Communication** — Message Templates (stage emails), Notifications (channel prefs + retention), Webhooks, **Message Queue** (scheduled/sent/failed/cancelled)
  - **Scheduling** — Calendar (Google connection), My Availability, Company Availability (cross-link with admin badge)
  - **Privacy & System** — Audit Log, Data & Privacy, Language
  Each group has a heading, icon (`hero-*`), short description; each item shows title + one-line subtitle + admin badge where applicable. The index becomes the hub with sidebar; each child page renders inside the same sidebar shell with active highlighting and a secondary Back link.
- **Top navigation — trimmed:** Keep primary items as **Jobs, Candidates, Interviews, Analytics, Assistant** (5). Remove **Import** and **Message Queue** from the top bar. **Settings** becomes a gear icon (`hero-cog-6-tooth`, admin only) next to the notification bell; alternative considered is Settings inside the user menu — decided as icon for 1-click admin access (see design).
- **Import — relocated to Candidates:** Add a secondary `Import CSV` button in `CandidatesLive.Index` header (beside `Add Candidate`), visible both when the list has results and in the empty state (already exists there). Keep route `/app/import` unchanged; only the top-nav entry is removed. Breadcrumb `Candidates > Import` stays.
- **Message Queue — relocated to Settings:** Move from top nav to **Settings → Communication → Message Queue**. Keep route `/app/messages-queue` unchanged (no redirect); only navigation entry moves. Consider a failure badge on the Communication group or Settings gear when failed messages exist (optional, not required for v1).
- **User menu — unified:** Collapse the currently scattered `theme_toggle` + `locale_switcher` + `user name` + `Logout` into a single avatar/name dropdown (`👤 Name ▾`) in the header. The dropdown contains: user identity (name + role), Theme segmented control (System/Light/Dark), Language (EN/IT), and Logout. Settings gear stays separate (icon) for admin 1-click; non-admins see no gear and reach personal settings via the hub filtered view.
- Preserve all existing routes (`/app/*` and `/:tenant_slug/app/*`); no URL renames, bookmarks stay valid.
- Fix role inconsistency: `router.ex` gates all settings under admin `live_session` while `index.ex` conditionally hides cards. Align so personal items (Language, Calendar, My Availability) are reachable by non-admins.
- Add a lightweight client-side filter above the sidebar (optional, deferred if not trivial).
- Update `site/features/*` and `site/.vitepress/config.ts` sidebar if any user-facing labels/menu paths change.

## Capabilities

### New Capabilities
- `settings-navigation`: Sidebar-based settings hub with semantic grouping, active-state highlighting, role-aware visibility (admin vs member), and optional text filter. Covers layout, grouping, navigation, and empty/filtered states. Now includes Message Queue as a Communication item.

### Modified Capabilities
- `app-navigation`: Top navigation is trimmed from 8 to 5 primary text links; Import and Message Queue entries are removed; Settings moves from text link to gear icon (admin only); theme/language/logout move from standalone header controls into a unified user dropdown. Settings landing page structure changes from flat grid to grouped sidebar.
- `company-availability`: Placement changes — no longer a standalone top-level card; lives under Organization (primary) with cross-link under Scheduling.
- `pipeline-config`: Discoverability changes — Pipeline moves under "Hiring Process" group. No functional change.
- `csv-import`: Entry point moves from top navigation to Candidates page header (secondary button). Import flow itself unchanged; only the navigation path changes. Breadcrumb and empty-state CTA remain.
- `email-scheduler`: Navigation entry moves from top nav to Settings → Communication → Message Queue. Queue functionality (tabs, bulk actions, edit, retry) unchanged; only discoverability changes. Optionally add a badge/indicator for failed messages.
