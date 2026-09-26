## Why

The current admin/member binary is too coarse: every sensitive action shares the same gate, so workspaces cannot delegate operational work (e.g. manage pipeline, delete candidates) without granting full admin. Frontend routes and AI tools duplicate the same binary check, causing drift.

## What Changes

- Replace the binary role gate with an action-based model: stable action keys (~15-20 grouped permissions) resolved to an effective permission set per membership.
- Introduce preset workspace roles: `admin` (all, locked), `recruiter` (hiring operations default), `interviewer` (scoped view + scorecards + availability). Existing `member` memberships migrate to `recruiter`.
- Make actions configurable per workspace: admins can toggle allowed actions per non-admin role from Settings → Team; only explicitly editable actions are toggleable, core admin actions stay locked.
- Single source of truth for both surfaces: UI hides routes, menu entries, and buttons where the action is not allowed; the AI agent hides tools from the model and re-checks at run/confirm time.
- Per-resource pipeline advancer/examiner rules stay as a second layer on top of role permissions (no change in behavior, only the role check underneath becomes permission-based).

## Capabilities

### New Capabilities
- `action-permissions`: action keys, preset defaults, effective permission resolution per membership, shared `can?` contract for UI and agent.
- `role-permission-config`: per-workspace admin UI to view and toggle allowed actions per non-admin role, with audit logging.

### Modified Capabilities
- `role-based-access`: requirements change from binary admin/member gates to permission checks; admin-only pages become permission-gated.
- `team-management`: invite/change-role flows use the new preset roles; team page hosts the permission matrix.
- `ai-agent-authorization`: tool gating moves from `required_role` (:any/:admin) to required action + hidden-unless-allowed, with enforcement at filter, run, and confirm time.
- `settings-navigation`: menu filtering moves from role-based groups to permission-based visibility.

## Impact

- New authorization module under `lib/treby/` (pure permission resolution, no HTTP/LiveView deps) consumed by `lib/treby_web/` (router hooks, SettingsNav, LiveViews) and `lib/treby/ai/` (Tools registry, Agent loop, Context).
- Migration via `mix ecto.gen.migration`: extend membership/invite role inclusion to new presets; new table (or tenant-scoped store) for per-role action overrides; backfill `member` → `recruiter`.
- AI tools: replace `required_role/0` with required-action declaration; `Context.build` carries effective permissions; tool list sent to the model is filtered (hidden, not just blocked).
- UI: `RequireRole` hook superseded by permission check; scattered `role == "admin"` template guards replaced by `can?`; settings team page gains Roles & permissions matrix.
- Tests: matrix tests for permission resolution, route guards, tool visibility/enforcement, migration of legacy members.
