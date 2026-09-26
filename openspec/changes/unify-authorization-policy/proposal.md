## Why

Authorization checks are spread across three parallel APIs (`Authorization.can?/allowed?/effective_*`, `Permissions.can?/actor`, `AI.Tools.authorize/effective/actor`) with duplicated role resolution and fail-closed logic. Every new permission or caller re-implements the same guard, increasing bug risk and review cost.

## What Changes

- Introduce a single policy entry-point `Policy.can?(actor, action)` backed by effective permission sets; keep `Authorization` as the permission-set source of truth.
- Introduce a single `Actor.from(socket | assigns | ctx | membership)` builder replacing the three `actor` builders.
- Deprecate (not remove) legacy wrappers: `Permissions.can?/3`, `Authorization.allowed?/2`, `AI.Tools.authorize/2` become thin delegates to `Policy`.
- Update LiveView template guards and AI tool choke-points to use the single entry-point; no behavior change for granted/denied decisions.
- Add contract tests covering fail-closed cases (nil actor, nil tenant, unknown role/action).

## Capabilities

### New Capabilities
- `authorization-policy`: unified policy check and actor builder contract (single `can?` path, fail-closed rules, actor normalization).

### Modified Capabilities
- `role-based-access`: requirements for how role checks resolve in LiveView now reference the unified policy instead of parallel helpers.
- `ai-agent-authorization`: requirements for how AI tools authorize actions now reference the unified policy instead of a separate `authorize` path.

## Impact

- Code: `lib/treby/authorization.ex`, `lib/treby_web/permissions.ex`, `lib/treby/ai/tools.ex`, `lib/treby/ai/context.ex`, LiveView guards in `pipeline_live`, `jobs_live/show`, `settings_live/*`, AI tool `run/3` choke-point.
- No DB migration, no new dependencies, no API breaking change (legacy functions delegate).
- Tests: new policy contract tests; existing `role-based-access` and `ai-agent-authorization` suites must still pass.
