## Context

After registration, new users land on a dashboard with four `0` stat cards and three "No X." text lines. Every page in the app is a dead end — empty states are terse gray text with no CTA, no illustrations, and no guidance. There is no onboarding flow, no checklist, no wizard. The "Welcome to Treby!" flash message is the only acknowledgment of registration.

The app currently has no shared empty state component. Jobs and Candidates pages each have inline, copy-pasted empty state divs. Pipeline has no empty state at all.

**Stakeholders:** New users (small business owners, startup recruiters) who need to go from registration → active usage quickly.

## Goals / Non-Goals

**Goals:**
- Guide new users through the 4 key setup steps: create job, add candidate, invite team, customize career page
- Make every empty page a guided onboarding moment, not a dead end
- Completion tracking derived from live state (no schema flag needed)
- Clean dismissal UX (per-session + permanent)

**Non-Goals:**
- Forced wizard or multi-step form that blocks app access
- Tooltips or guided tour overlay (too fragile, too complex)
- Onboarding for existing users with existing data (they'll see the checklist naturally — it'll show as complete or absent)
- Changing any business logic in jobs, candidates, teams, or branding

## Decisions

### Decision 1: Checklist pattern over wizard

**Chosen:** Persistent checklist on dashboard, dismissible.

**Alternatives considered:**
- *Multi-step wizard before app access*: Rejected. Users need to explore freely. Forcing completion of all steps before access creates friction and drop-off. Some steps (like inviting team) require info the user may not have ready.
- *Tooltips/walkthrough*: Rejected. Fragile across screen sizes, annoying on repeat visits, and hard to maintain with Phoenix LiveView.

**Rationale:** The checklist respects user autonomy. They can do steps in any order, skip and come back, or ignore entirely. The smart empty states on each page serve as a secondary safety net.

### Decision 2: Live-state completion checking (no DB flag)

**Chosen:** Compute completion by querying actual tenant state in `mount/3`.

**Alternatives considered:**
- *`onboarding_completed_at` timestamp on users*: Rejected. Creates stale state risk — user completes onboarding, deletes all jobs, checklist stays hidden. Also requires a migration.
- *`onboarding_step_completed` map on users*: Rejected. Over-engineered for 4 boolean checks. Duplicates state that already exists in the database.

**Rationale:** Querying `has_jobs?`, `has_candidates?`, etc. is cheap (single-row counts), self-healing, and requires zero schema changes. The queries already exist implicitly in the dashboard data loading.

### Decision 3: Shared empty state component

**Chosen:** Create a `<.empty_state>` function component in `core_components.ex`.

**Alternatives considered::
- *Keep inline empty states per page*: Rejected. Leads to inconsistency and duplicated code.
- *Separate EmptyStateLive LiveComponent*: Rejected. Overkill for a pure display component. Function component is simpler and gets imported everywhere automatically.

**Rationale:** A function component in core_components gives us consistent empty states across all pages with minimal effort. Attrs: `icon`, `title`, `description`, `action` (link), `action_label`.

### Decision 4: Dismiss UX — session dismiss + permanent opt-out

**Chosen:**
- **X button**: Toggles `@show_onboarding` assign — hides for current page load, returns on next visit
- **"Don't show again" link**: Sets a `onboarding_checklist_dismissed` boolean column on the users table via a quick handle_event. The checklist checks this in mount and renders nothing if true.

**Alternatives considered:**
- *localStorage only*: Rejected. Doesn't sync across devices, invisible to server, hard to test.
- *Session-only dismiss*: Rejected. Users who dismiss would see it again immediately on next login — feels naggy.

**Rationale:** A single boolean column on users is the simplest durable preference. One migration, one boolean, clean query.

### Decision 5: Checklist placement — dashboard only

**Chosen:** Rendered inside the dashboard LiveView, between the welcome header and the stat cards.

**Alternatives considered:**
- *Layouts.app (every authenticated page)*: Rejected. Too intrusive. The checklist is a starting-point guide, not a persistent banner.
- *Dedicated /app/onboarding page*: Rejected. Extra navigation step. Users should see it where they already are.

**Rationale:** Dashboard is the landing page after login and the natural "home base." Placing it there ensures visibility without being inescapable.

## Risks / Trade-offs

**[Risk] Checklist feels naggy** → Mitigation: Permanent dismiss option. Auto-hides when all steps complete. Compact design (not a full-width banner).

**[Risk] Completion queries add DB load** → Mitigation: These are single-row COUNT queries with WHERE tenant_id = ?. Indexed. Negligible impact. Could add short TTL cache later if needed, but won't be necessary at small business scale.

**[Risk] "Don't show again" is irreversible** → Mitigation: Could add a "Reset onboarding" link in Settings for users who want it back. Low priority — skip in v1, add if requested.

**[Trade-off] No illustrations in empty states** → We'll use hero icons (already available via `<.icon>`) instead of custom illustrations. Keeps the change scope tight while still being visually richer than plain text.

## Migration Plan

1. Create migration: `add_onboarding_checklist_dismissed_to_users` — adds `onboarding_checklist_dismissed :boolean, default: false, null: false`
2. Create the `<.empty_state>` component in core_components.ex
3. Create the `<.onboarding_checklist>` function component
4. Update DashboardLive to compute steps and render checklist
5. Update Jobs, Candidates, Pipeline empty states to use `<.empty_state>`
6. Run `mix precommit` to verify

**Rollback:** Revert code changes, drop the migration column.

## Open Questions

None — design is settled.
