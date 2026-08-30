## Why

Team invites currently always create a new user row via `build_assoc(tenant, :users)`, so inviting `alice@example.com` who already belongs to Tenant A into Tenant B duplicates the identity (two rows, two passwords) and breaks the "one email, one password, many memberships" invariant required for multi-workspace users. Invites must re-use the existing identity.

## What Changes

- On `GET /invite/:token` and `POST /invite/:token`, the authoritative identity is re-fetched by `invite.email` via global `Accounts.get_user_by_email/1` (case-insensitive), not by session `current_user`.
- If `invite.email` does not exist: show registration form (email locked) → `POST` creates user (global) + `membership(tenant_id, role)` → mark invite accepted → `302 /:tenant_slug/app`.
- If `invite.email` exists and visitor is not authenticated: prompt "Log in as alice@… to join Workspace" → after `POST /session` create membership idempotently → `302 /:tenant_slug/app`.
- If `invite.email` exists and visitor is authenticated as the same user: create membership idempotently (no duplicate) and redirect to `/:tenant_slug/app` (no password form).
- If `invite.email` exists and visitor is authenticated as a different user (e.g. bob clicking alice's invite): do not create membership for the session user; show interstitial "You're logged in as bob@… but this invite is for alice@… — [Log out and continue as alice] / [Cancel]".
- Membership creation is idempotent — `UNIQUE(user_id, tenant_id)`; re-accepting an already-accepted invite just redirects.
- This change assumes `workspace-picker-switcher` (memberships table, global `lower(email)` uniqueness, URL-scoped workspaces) is applied first.

## Capabilities

### New Capabilities
- (none — reuses `workspace-switching` from prerequisite)

### Modified Capabilities
- `team-management`: invite re-uses existing identity via re-fetch by email, idempotent membership creation, mismatch interstitial, role is per-membership, all redirects land on `/:tenant_slug/app`.

## Impact

- **Prerequisite**: `workspace-picker-switcher` must be applied first (needs `memberships` table and global email uniqueness).
- **Modules**: `lib/treby_web/controllers/invite_controller.ex`, `lib/treby/accounts/*` (global email lookup), `lib/treby/memberships/*`, `lib/treby/invites/*`, `lib/treby_web/router.ex` (redirect targets become `/:slug/app`), email template link stays `/invite/:token`.
- **DB**: no new migration beyond prerequisite; relies on `memberships` unique index for idempotency.
- **Docs**: `site/` — Settings → Team → Invite flow for existing identity.
