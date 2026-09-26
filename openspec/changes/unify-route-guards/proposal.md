## Why

Route-guard logic is tripled: the `RequireMembership` plug (controllers) and the `RequireMembership` hook (LiveView) repeat the same slug-to-tenant plus membership lookup, `RequirePermission` re-reads the membership the first hook already assigned, and every new permission-gated `live_session` copy-pastes the same 5-line `on_mount` list. A dead deprecated `RequireRole` hook is still in the tree. Any fix to guard behavior must be applied in three places.

## What Changes

- Add `Treby.Memberships.access_for/2` as the single guard core: `(user_id, slug) -> {:ok, %{tenant, membership, available}} | {:error, :no_tenant | :no_membership}`. Both the plug and the hooks use it.
- Rewrite `TrebyWeb.Plugs.RequireMembership` and `TrebyWeb.Hooks.RequireMembership` as thin adapters over `access_for/2`, preserving current redirects and flash messages.
- Simplify `TrebyWeb.Hooks.RequirePermission` to consume `current_membership`/`current_tenant` assigns (resolved by `RequireMembership` first) and fall back to `access_for/2` only when assigns are missing; collapse the slug/session clause pairs.
- Delete `TrebyWeb.Hooks.RequireRole` (deprecated, zero callers).
- Deduplicate `router.ex`: one module attribute for the shared `on_mount` base list, one helper for permission-gated sessions. No route or behavior change.

## Capabilities

### New Capabilities

- `route-guards`: membership gate and permission gate behavior for controller and LiveView routes (redirect targets, flash messages, fail-closed on missing membership).

### Modified Capabilities

- (none — guard behavior is preserved, only the implementation is unified)

## Impact

- `lib/treby/memberships.ex`: new `access_for/2` function, no schema change.
- `lib/treby_web/plugs/require_membership.ex`, `lib/treby_web/hooks/require_membership.ex`, `lib/treby_web/hooks/require_permission.ex`: rewritten as adapters.
- `lib/treby_web/hooks/require_role.ex`: deleted.
- `lib/treby_web/router.ex`: `on_mount` lists deduplicated, routes unchanged.
- No migrations, no new dependencies.
