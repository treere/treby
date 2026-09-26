## 1. Policy core

- [x] 1.1 Add `Treby.Authorization.Actor.from/1` normalizing socket, assigns, ctx, membership (fail-closed, string/atom roles)
- [x] 1.2 Add `Treby.Authorization.Policy.can?/2` for actor map and MapSet paths (never raises)
- [x] 1.3 Add contract tests: allow, nil/unknown deny, MapSet vs actor parity, string vs atom role

## 2. Delegation

- [x] 2.1 Delegate `TrebyWeb.Permissions.can?/3` and `actor/1` to Policy/Actor (comment-marked legacy path; attribute deprecation deferred for warnings_as_errors)
- [x] 2.2 Delegate `Treby.AI.Tools.authorize/2`, `effective/1`, `actor/1` to Policy/Actor
- [x] 2.3 Simplify `Treby.AI.Context` permission resolution to use Actor builder

## 3. Caller migration

- [x] 3.1 Migrate `RequirePermission` hook to Policy check; templates resolve via delegating `Permissions.can?` (direct rewrite deferred)
- [x] 3.2 Migrate `Treby.AI.Tools.run/3` choke-point to Policy check
- [x] 3.3 Run `mix precommit`, `mix test` for authorization, permissions, AI tool suites
