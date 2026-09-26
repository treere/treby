## Why

Membership lookups and actor derivation are still scattered after the policy (`unify-authorization-policy`) and route-guard (`unify-route-guards`) unifications: settings LiveViews re-query `Memberships.get_membership/2` per mount, contexts repeat the nil-guard `actor && actor.id` ~29 times, and no single `current_actor` assign exists. One mount-time assign plus a nil-safe id helper removes the duplication.

## What Changes

- Assign `socket.assigns.current_actor` once in the membership guards (plug `RequireMembership` and hook `RequireMembership`), derived from the already-loaded tenant + membership via `Authorization.Actor.from/2`. The guards only continue with a membership present, so no nil path exists there; contexts keep their nil-actor default.
- Add `Authorization.Actor.id/1` nil-safe helper (`nil -> nil`, else `actor.id`) and migrate the `actor && actor.id` repetitions in contexts and AI tools to it.
- Migrate per-mount `Memberships.get_membership/2` lookups in settings LiveViews (`team`, `webhooks`, `language`, `company_availability`) and controllers (`invite`, `choose_tenant`) to reuse the guard assigns where the guard already ran.
- Reduce `current_membership` template pass-through where `current_actor` suffices (starting with `messages_queue_live`).
- No behavior change: guards keep the same 404/redirect/flash contract; contexts keep accepting a possibly-nil actor.

## Capabilities

### New Capabilities
- `current-actor`: single mount-time `current_actor` assign plus nil-safe `Actor.id/1` helper covering all actor derivation and id extraction.

### Modified Capabilities
- `route-guards`: guards additionally assign `current_actor` (observable in templates); resolution and fail-closed semantics unchanged.

## Impact

- Modules: `Treby.Authorization.Actor` (new `id/1`), `TrebyWeb.Plugs.RequireMembership`, `TrebyWeb.Hooks.RequireMembership`, settings LiveViews (`team`, `webhooks`, `language`, `company_availability`), `InviteController`, `ChooseTenantController`, contexts with `actor && actor.id` (~29 sites), `messages_queue_live` template.
- Depends on: `unify-authorization-policy` (`Actor.from`), `unify-route-guards` (`access_for` adapters) — both archived.
- No migrations. No new dependencies.
