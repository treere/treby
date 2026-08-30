## Context

`users` is tenant-owned (`tenant_id` FK + `UNIQUE(tenant_id,email)` and `role` on the user row). Public pages already use `/:tenant_slug/careers`, but the authenticated app is session-scoped at `/app/*` — `Plugs.Auth` sets `current_user` via `user_id` and `Repo.preload(user,:tenant)`, `Plugs.Tenant` only handles `:from_session` vs `:from_slug`. Login/registration/password-reset all do global email lookups while invites do `build_assoc(tenant,:users)`, so the DB allows the same email in two tenants, the app blocks it inconsistently. Moving to one email/one password with URL-scoped workspaces requires a membership layer and a picker/switcher.

## Goals / Non-Goals

**Goals:**
- One identity per email (global `lower(email)` uniqueness, one bcrypt password) with a `memberships` row per `(user,tenant,role)`.
- URL is workspace truth: `/:tenant_slug/app/*` + `RequireMembership` gate; session only holds `user_id`.
- Login picker when `memberships>1` and in-app switcher plus authenticated "Create new company".
- Backfill existing `users.tenant_id` into `memberships` with zero downtime.

**Non-Goals:**
- Subdomain routing, SSO/OAuth rework, candidate-portal changes.
- Per-membership display names, per-membership passwords, slug-history redirects.

## Decisions

**1. Identity vs membership split.**
`users` keeps `email`, `password_hash`, `name`, `locale`, `onboarding_checklist_dismissed`; `role` is removed from `users` and lives on `memberships`. Rejected: keeping `users.tenant_id` as primary tenant — would keep the login race on `get_by(email)`.

**2. Global email via `lower(email)` unique index.**
Changeset normalizes `String.downcase/1` before validation; DB enforces `unique_index :users, "lower(email)"`. Add `unique_index :memberships, [:user_id, :tenant_id]`. Rejected: per-tenant uniqueness.

**3. URL as truth.**
Chosen: `scope "/:tenant_slug/app" → pipe :require_auth → :require_membership` where `:require_membership` does `tenant=get_tenant_by_slug!`, `membership=get_membership!(user.id,tenant.id)` else 403→`/choose-tenant`. Session `tenant_id` is dropped (kept read-only for one release). Rejected: session-scoped workspace — bookmarks would be ambiguous.

**4. Login → picker branching.**
`POST /session` authenticates globally, then `list_tenants_for_user`: `1→302 /:slug/app`, `N→302 /choose-tenant`. `GET /choose-tenant` lists `available_tenants` with role badges; `POST /choose-tenant {slug}` verifies membership. Rejected: per-tenant login forms (`/:slug/login`).

**5. Switcher placement.**
Header between logo and primary nav on desktop, same in `#mobile-nav-drawer`; shown only if `length(available_tenants)>1`; includes checkmark, role badge, "+ Create new company" link.

**6. Authorization.**
New `on_mount :require_membership` assigns `current_user`, `current_tenant` (from slug), `current_membership`, `available_tenants`. `RequireRole` is updated to check `current_membership.role`. Domain queries keep `where tenant_id == current_tenant.id` — isolation unchanged.

## Risks / Trade-offs

- **Router churn (~40 LiveViews) `~p"/app"` → `~p"/#{@current_tenant.slug}/app"`.** → Mitigation: mechanical replacement, covered by `mix precommit` and LiveView tests.
- **Slug renames break URLs.** → Mitigation: treat slug as immutable post-create; rename deferred to future redirect table.
- **Legacy sessions with `tenant_id` cookie.** → Mitigation: `Auth` ignores it; `Tenant` validates slug membership and silently drops legacy key.
- **Duplicate `lower(email)` via old invite path.** → Mitigation: pre-migration duplicate check; if found, merge into one user row (earliest password_hash/name, create missing memberships) or abort for human review.
- **Public `/:slug/careers` collision.** → Mitigation: mount `/:slug/app` before public catch-all.
- **Extra indexed lookup per request.** → Mitigation: covered by membership unique index; no external cache.

## Migration Plan

1. Migration A (additive): create `memberships` table + indexes, add `lower(email)` unique index on `users`; keep `users.tenant_id/role`.
2. Dual-write: `Accounts.create_user` success also inserts `memberships`; `list_users_for_tenant` joins via `memberships`.
3. Backfill: `INSERT INTO memberships SELECT id, tenant_id, role FROM users ON CONFLICT DO NOTHING`.
4. Flip reads: `Auth` + `on_mount` switch to membership gate; router moves `/app` → `/:slug/app`; legacy `GET /app/*` → `302 /choose-tenant`/`/:slug/app`.
5. Cleanup (next release): make `users.tenant_id` nullable then drop column + old `UNIQUE(tenant_id,email)` and `users.role`.

## Open Questions

- Should `GET /app` redirect to `/choose-tenant` or to last-visited slug (signed cookie)?
- Remember last workspace via cookie for returning users hitting `/login`?
- Forbid slug edits in UI after creation?
