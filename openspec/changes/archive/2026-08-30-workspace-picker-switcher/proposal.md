## Why

Treby ties identity to a single tenant (`users.tenant_id` + `UNIQUE(tenant_id, email)`), yet login and registration treat email as globally unique. Users who run multiple businesses cannot use one email/password across workspaces, and the app's session-scoped `/app/*` URLs cannot disambiguate which workspace is active. A picker and in-app switcher with URL-scoped workspaces are needed.

## What Changes

- **BREAKING** Email becomes globally unique (`unique_index :users, "lower(email)"`, case-insensitive normalization). One bcrypt password per identity on `users`.
- Introduce `memberships` table (`user_id` FK, `tenant_id` FK, `role` string, timestamps) with `UNIQUE(user_id, tenant_id)`. `role` moves from `users` to `memberships` — a user can be admin in one workspace and member in another.
- Authenticated app routes move from session-scoped `/app/*` to URL-scoped `/:tenant_slug/app/*`. Slug is the source of truth; session only holds `user_id`. Legacy `GET /app/*` redirects to `/choose-tenant` or `/:slug/app`.
- Login flow: global `POST /session` authenticates by email+password, then:
  - 1 membership → `302 /:slug/app`
  - N memberships → `302 /choose-tenant` picker → `POST /choose-tenant {slug}` → `302 /:slug/app`
- In-app workspace switcher in header/drawer (visible when `memberships.count > 1`) plus "Create new company" (`POST /tenants` → new tenant + admin membership → `302 /:new_slug/app`).
- Anonymous `/register` with an already-registered email redirects to login ("log in, then Create company" — preserves one-password invariant).
- Backfill: every `users.tenant_id` becomes a `memberships` row; `users.tenant_id`/`users.role` kept nullable for one release then removed.

## Capabilities

### New Capabilities
- `workspace-switching`: workspace picker on login and in-app switcher with URL-scoped navigation and authenticated "Create new company".

### Modified Capabilities
- `authentication`: global email uniqueness, one password per identity, login → picker branching, session holds only `user_id`, authenticated create-company flow.
- `multi-tenancy`: introduce `memberships` (role per membership, uniqueness), URL-scoped workspace routing (`/:tenant_slug/app/*`), `current_membership` + `available_tenants`, slug immutability, backfill and self-hosted single-tenant behavior (picker/switcher hidden when count == 1).

## Impact

- **DB**: `memberships` migration (`unique_index` + indexes), `lower(email)` unique index on `users`, backfill, later removal of `users.tenant_id`/`users.role`.
- **Modules**: `lib/treby/accounts/*`, `lib/treby/memberships/*` (new), `lib/treby/tenants/*`, `lib/treby_web/plugs/auth.ex`, `lib/treby_web/plugs/tenant.ex` / new `require_membership`, `lib/treby_web/hooks/require_membership.ex` + `require_role.ex`, `lib/treby_web/controllers/session_controller.ex` + `registration_controller.ex`, `lib/treby_web/router.ex`, `lib/treby_web/components/layouts.ex`, ~40 LiveViews (`current_user.role` → `current_membership.role`, `~p"/app/…"` → `~p"/#{@current_tenant.slug}/app/…"`), legacy redirect.
- **Docs**: `site/` user manual — login/picker, switcher, create company; regenerate screenshots.
