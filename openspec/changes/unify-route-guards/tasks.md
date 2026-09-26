## 1. Guard core

- [x] 1.1 Add `Treby.Memberships.access_for/2` returning `{:ok, %{tenant, membership, available}} | {:error, :no_tenant | :no_membership}` (verify: `mix test test/treby/memberships_test.exs`)
- [x] 1.2 Contract-test `access_for/2`: valid membership, unknown slug, user without membership (verify: new tests green)

## 2. Thin adapters

- [x] 2.1 Rewrite `Plugs.RequireMembership` over `access_for/2`, preserving 404 and redirect+flash (verify: existing plug/router tests green)
- [x] 2.2 Rewrite `Hooks.RequireMembership` over `access_for/2`, preserving halt targets, flashes, and legacy `/app` fallback (verify: `mix test test/treby_web`)
- [x] 2.3 Simplify `Hooks.RequirePermission`: consume assigns, fallback to `access_for/2`, collapse slug/session clauses (verify: `mix test test/treby_web/hooks/require_permission_test.exs`)
- [x] 2.4 Delete `Hooks.RequireRole` after grep confirms zero callers (verify: `grep -R RequireRole lib test` clean, `mix compile --warnings-as-errors`)

## 3. Router dedup

- [x] 3.1 Extract shared `on_mount` base to module attribute plus permission-session helper; keep all routes identical (verify: `mix compile`, route list diff empty via `mix phx.routes | diff`)
- [x] 3.2 Contract-test guards end to end: anonymous → login, outsider → choose-tenant, unauthorized action → dashboard+flash, authorized → cont (verify: new hook tests green)

## 4. Verify

- [x] 4.1 Run `mix precommit` and `openspec validate --strict`, fix all issues
