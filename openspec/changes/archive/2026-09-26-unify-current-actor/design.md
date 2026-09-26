## Context

Two prior changes unified the authorization core: `unify-authorization-policy` introduced `Authorization.Actor.from/1,2` (single normalization, fail-closed, never raises) and `unify-route-guards` introduced `Memberships.access_for/2` with thin plug/hook adapters. Both guards already load tenant + membership and assign `current_tenant` / `current_membership`, but nothing derives the actor once per mount. Settings LiveViews (`team`, `webhooks`, `language`, `company_availability`) still call `Memberships.get_membership/2` redundantly, and contexts repeat the nil-guard `actor && actor.id` in ~29 places. No `current_actor` assign exists anywhere (verified by grep).

## Goals / Non-Goals

**Goals:**
- One mount-time `socket.assigns.current_actor`, derived with zero extra queries from assigns the guards already load.
- One nil-safe `Authorization.Actor.id/1` replacing all `actor && actor.id` repetitions.
- Remove redundant `get_membership/2` lookups in LiveViews mounted under the guards.

**Non-Goals:**
- No change to guard resolution, redirects, flash, or fail-closed semantics (owned by `route-guards`).
- No change to the actor shape or `Policy.can?/2` (owned by `authorization-policy`).
- No removal of `current_membership` / `current_tenant` assigns (`RequirePermission` and `Actor.from` read them).
- Controllers outside the LiveView guard pipeline (`choose_tenant`, `invite`) keep direct lookups unless assigns are proven present.
- No context signature changes: contexts keep accepting a possibly-nil actor.

## Decisions

**1. Derive `current_actor` inside the existing guards, not a new `on_mount`.**
Both `Plugs.RequireMembership` and `Hooks.RequireMembership` already hold tenant + membership at assign time, so `Actor.from(membership, tenant)` costs zero queries and covers every LiveView under the guards automatically. A separate `on_mount` would duplicate the load-or-read-assigns branching and introduce ordering constraints with `RequirePermission`. The guards only continue with a membership present, so no nil path exists there; the unreachable catch-all clause is deleted.

**2. `Actor.id/1` helper instead of inline nil-guards.**
`actor && actor.id` appears ~29 times across contexts and AI tools. A single `id(nil) -> nil` / `id(actor) -> actor.id` clause documents the nil contract in one place and makes future shape changes mechanical. Alternative (pattern-match at each site) preserves the scattering this change exists to remove.

**3. Migrate only LiveViews proven under the guards; leave controllers alone.**
Settings LiveViews mount through `RequireMembership`, so their `get_membership/2` calls are provably redundant and become plain assign reads. `ChooseTenantController` runs before any membership is known and `InviteController` sits outside the LiveView pipeline, so their lookups stay — migrating them would trade a local query for implicit conn-assign coupling.

**4. Additive assigns only.**
`current_actor` is added next to `current_membership` / `current_tenant`; nothing is renamed or removed. Templates adopt `current_actor` opportunistically (starting with `messages_queue_live` pass-through); unguarded LiveViews (public pages) simply see a missing assign and must keep handling nil.

## Risks / Trade-offs

- [Risk] A LiveView mounted without the guards reads a missing `current_actor` assign → Mitigation: migrations touch only guard-mounted LiveViews; templates keep nil handling.
- [Risk] `Actor.from(membership, tenant)` with nil membership could surprise → Mitigation: it returns a nil-id/nil-role actor that denies; covered by a spec scenario locking fail-closed.
- [Risk] `Actor.id/1` hides nil actors instead of failing loudly → Mitigation: that is the existing contract (all 29 sites already pass nil through); audit logging stays untouched.
- [Trade-off] Controllers keep direct lookups → accepted: explicit query beats implicit coupling outside the guard pipeline.
