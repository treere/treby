## 1. Database migration and backfill

- [x] 1.1 Generate migration `mix ecto.gen.migration create_memberships` — `memberships` table `id` binary_id, `user_id` FK, `tenant_id` FK, `role` not null, timestamps, `unique_index [:user_id, :tenant_id]`, indexes; add `unique_index :users, "lower(email)"`; verify `mix ecto.migrate` + `mix ecto.rollback`.
- [x] 1.2 Add duplicate guard to migration: query `lower(email)` duplicates across tenants before backfill; document merge/abort path if found.
- [x] 1.3 Backfill: `INSERT INTO memberships (user_id, tenant_id, role) SELECT id, tenant_id, role FROM users ON CONFLICT DO NOTHING`; verify row count equals users count.
- [x] 1.4 Keep `users.tenant_id` and `users.role` nullable for one release (no drop yet).

## 2. Contexts and schema

- [x] 2.1 Create `lib/treby/memberships/membership.ex` + `lib/treby/memberships.ex` with `create_membership/1`, `get_membership/2`, `list_tenants_for_user/1`, `list_members_for_tenant/1`, `member?/2`, `remove_membership/2`.
- [x] 2.2 Update `lib/treby/accounts/user.ex` — normalize `lower(email)`, `unique_constraint` on `lower(email)`, `has_many :memberships`, drop `role` from changeset (role lives on membership).
- [x] 2.3 Update `lib/treby/accounts/accounts.ex` — `get_user_by_email/1` and `email_registered?/1` use `lower(email)`; `authenticate_user/2` stays global; `list_users_for_tenant` delegates via memberships.

## 3. Authentication and routing

- [x] 3.1 Update `lib/treby_web/plugs/auth.ex` to load only `user_id` from session and assign `current_user`; ignore legacy `tenant_id` in session.
- [x] 3.2 Add `lib/treby_web/plugs/require_membership.ex` and `lib/treby_web/hooks/require_membership.ex` — load `tenant` by `tenant_slug`, verify `member?(user.id, tenant.id)` else 403/redirect to `/choose-tenant`; assign `current_user`, `current_tenant`, `current_membership`, `available_tenants`.
- [x] 3.3 Refactor `lib/treby_web/router.ex` — move `"/app"` → `"/:tenant_slug/app"` behind `[:browser, :require_auth, :require_membership]`; add `GET /choose-tenant` + `POST /choose-tenant` (verify membership) + `POST /tenants` (create company); keep `GET /app/*` legacy redirect; ensure public `/:tenant_slug/careers` stays after app scope.
- [x] 3.4 Update `lib/treby_web/controllers/session_controller.ex` — `create/2` branches: 1 membership → `302 /:slug/app`, N → `302 /choose-tenant`; add `choose_tenant` actions.
- [x] 3.5 Update `lib/treby_web/controllers/registration_controller.ex` — if verified email exists, redirect to login with flash ("log in, then Create company"); on new identity create user + membership admin → `302 /:slug/app`.
- [x] 3.6 Update `lib/treby_web/hooks/require_role.ex` to check `current_membership.role`.
- [x] 3.7 Add `POST /tenants` authenticated handler for switcher "Create new company" — `Tenants.create_tenant` + admin membership → `302 /:new_slug/app`.

## 4. LiveView and UI

- [x] 4.1 Update `lib/treby_web/components/layouts.ex` — header switcher dropdown (active checkmark, role badge) when `length(available_tenants) > 1` plus "+ Create new company"; mirror in `#mobile-nav-drawer`.
- [x] 4.2 Create picker at `lib/treby_web/live/choose_tenant_live.ex` or controller view — list `available_tenants` with role, `POST /choose-tenant` verifies membership before redirect; add DOM IDs.
- [x] 4.3 Sweep LiveViews (~40) — replace `current_user.role` → `current_membership.role` and `~p"/app/…"` → `~p"/#{@current_tenant.slug}/app/…"`; run `mix compile` clean.
- [x] 4.4 Update `lib/treby_web/live/settings_live/team.ex` to list via memberships and remove membership (not user row).

## 5. Tests

- [x] 5.1 Add `test/treby/memberships_test.exs` — create, uniqueness per pair, role per membership, `member?/2`.
- [x] 5.2 Add `test/treby_web/integration/auth_workspace_test.exs` — global lower(email) uniqueness, login 1 vs N, `/choose-tenant` picker enforces membership, URL without membership → 403, switcher navigation, create second company, legacy `/app` redirect.
- [x] 5.3 Update existing integration/LiveView tests asserting `~p"/app"` / `session["tenant_id"]` / `current_user.role` to new URL + membership expectations; `mix test` green.

## 6. Specs and docs

- [x] 6.1 Update specs at `openspec/specs/authentication/spec.md`, `openspec/specs/multi-tenancy/spec.md`, add `openspec/specs/workspace-switching/spec.md` with Purpose/Requirements and Scenario WHEN/THEN from deltas; `openspec validate --strict`.
- [x] 6.2 Update `site/features/*.md`, `site/features/index.md` and sidebar in `site/.vitepress/config.ts` (login, switcher, create company); regenerate screenshots `node scripts/screenshots.mjs`; verify `cd site && npm run build`.
- [x] 6.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
