## 1. Prerequisite

- [x] 1.1 Verify `workspace-picker-switcher` is applied (memberships table + global `lower(email)` uniqueness + `/:tenant_slug/app` routing exist); `mix ecto.migrate` clean.

## 2. Controller and context

- [x] 2.1 Update `lib/treby_web/controllers/invite_controller.ex` — `show/2` and `create/2` re-fetch `user = Accounts.get_user_by_email(invite.email)` (global lower lookup) as authoritative identity; branch: (a) no user → locked-email registration form, (b) existing + anon → "Log in as X to join Y" prompt, (c) existing + same user → idempotent `Memberships.create` + redirect `/:slug/app`, (d) existing + different user → interstitial "You're logged in as B but invite is for A — Log out and continue as A".
- [x] 2.2 Ensure `Memberships.create` is idempotent via `UNIQUE(user_id, tenant_id)` — duplicate just redirects; set `invite.accepted_at` on first accept only.
- [x] 2.3 Change all invite success redirects to `/:tenant_slug/app` (from plain `/app`).
- [x] 2.4 Update `lib/treby_web/live/settings_live/team.ex` email copy if needed and keep invite creation tenant-scoped to `current_tenant` from URL.

## 3. Tests

- [x] 3.1 Extend `test/treby_web/integration/invite_flow_test.exs` — invite to existing identity re-uses user (no duplicate row), idempotent re-accept, anon prompt, same-user vs different-user interstitial, redirect to `/:slug/app`.
- [x] 3.2 Run `mix test test/treby_web/integration/invite_flow_test.exs` and `mix test` until green.

## 4. Specs and docs

- [x] 4.1 Update spec at `openspec/specs/team-management/spec.md` with Purpose/Requirements and Scenario WHEN/THEN from delta `specs/team-management/spec.md`; `openspec validate --strict`.
- [x] 4.2 Update `site/features/*.md` for Settings → Team → Invite (existing identity) including interstitial copy; update `site/features/index.md` + sidebar if needed; regenerate screenshots `node scripts/screenshots.mjs`; `cd site && npm run build`.
- [x] 4.3 Run `mix precommit` and `openspec validate --strict` and fix issues.
