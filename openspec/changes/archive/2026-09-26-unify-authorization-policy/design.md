## Context

`Treby.Authorization` owns action keys, preset defaults, overrides, `effective_*` and `can?/allowed?`. `TrebyWeb.Permissions` duplicates fail-closed `can?/3` plus an `actor/1` builder for LiveView assigns. `Treby.AI.Tools` duplicates `effective/1`, `actor/1`, `authorize/2` for agent ctx maps. `Treby.AI.Context` duplicates permission resolution again. Result: 3 actor builders, 3 effective paths, 4 check entry-points. Decisions must stay fail-closed and DB-backed overrides must keep working.

## Goals / Non-Goals

**Goals:**
- One check path: `Policy.can?(actor_or_effective, action)` used by LiveView, router hooks, and AI tools.
- One actor builder: `Actor.from/1` normalizing socket / assigns / ctx / membership.
- Legacy wrappers delegate, no behavior change on grant/deny.

**Non-Goals:**
- No change to role presets, override schema, or admin locked actions.
- No router `live_session` restructuring (punto 2), no tenant-scope refactor (punto 4).
- No new dependency.

## Decisions

- **New module `Treby.Authorization.Policy`, actor as plain map `%{id, role, permissions}`.**
  Rationale: keeps `Authorization` as permission-set source, `Policy` as decision layer; plain map avoids struct churn across LiveView/AI.
  Alternative considered: extend `Authorization.can?` with actor clauses — rejected, mixes set logic with actor normalization.
- **Single normalization `Treby.Authorization.Actor.from(source)` accepting `%{assigns: _} | assigns map | ctx map | membership + tenant`.**
  Rationale: one place for nil-role, string/atom role, missing tenant fail-closed.
  Alternative: separate `Permissions.actor` + `Tools.actor` — rejected, this is the duplication.
- **Fail-closed + rescue-free core:** `Policy.can?` returns boolean, never raises; DB errors in `effective_for` fall back to preset defaults at `Actor.from` boundary (preserves role-only filtering), while nil role or unresolvable tenant on the membership path denies; rescues are centralized instead of scattered per call.
  Rationale: current `rescue _ -> false` scattered in 5 places; centralize once without changing grant behavior for preset roles.
- **Delegation, not removal:** `Permissions.can?/3`, `Authorization.allowed?`, `Tools.authorize/2`, `Tools.effective/1` stay as thin delegates for one release, marked with `# Legacy entry-point` comments (not `@deprecated` attributes, which would break the build under `warnings_as_errors: true` with ~96 call sites).
  Rationale: ~30 call sites; atomic rewrite risks breakage. ponytail: smallest diff that unifies.
- **No caching of effective sets in socket beyond current assigns.**
  Rationale: overrides change via admin UI; stale cache = privilege escalation. Add cache only when measured.

## Risks / Trade-offs

- [Stale delegates diverge] → Delegates are one-liners to `Policy`; marked `# Legacy entry-point` (attribute deprecation deferred until callers migrate, to keep `warnings_as_errors` green).
- [DB-backed `effective_for` called more often] → `Actor.from` resolves once per mount/ctx build; callers pass actor, not role+tenant.
- [String/atom role mismatch] → Normalize once in `Actor.from` via existing `normalize_role`.

## Migration Plan

1. Add `Actor` + `Policy` with contract tests.
2. Switch `Permissions.can?`, `Tools.authorize/effective`, `Context.permissions_for` to delegates.
3. Migrate the `RequirePermission` hook to `Policy.can?`; template guards (`pipeline_live`, `jobs_live/show`, `settings_live/*`) resolve through the same path via the delegating `Permissions.can?` (direct rewrite deferred to avoid a ~30-site diff).
4. Migrate `Tools.run/3` choke-point to `Policy` (via `authorize/2` delegate).
5. Rollback: delegates preserve old API; revert commits per-step.

## Open Questions

- None blocking. Follow-up (out of scope): router hook consolidation, tenant-scoped repo wrapper.
