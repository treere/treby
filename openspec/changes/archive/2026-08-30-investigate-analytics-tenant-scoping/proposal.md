## Why

`GET /app/analytics` reports `Total Candidates 14` on a tenant with only 2 local candidates (Friction Co 86 retest). Queries likely miss `where tenant_id = ^tenant.id`, leaking cross-tenant data. This is a correctness/privacy issue.

## What Changes

- Scope all analytics queries by `tenant_id` (candidates, applications, conversions, pipeline snapshot).
- Add regression test: create 2 tenants with 2/3 candidates each, assert `Analytics` counts are isolated.
- Verify `Dashboard` pipeline snapshot also uses `tenant_id`.

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `analytics`: Tenant isolation for counts.

## Impact

- `lib/treby/analytics` (or `lib/treby/candidates`, `lib/treby/pipeline` query callers) — add `where tenant_id`.
- `lib/treby_web/live/analytics_live/index.ex` + `lib/treby_web/live/dashboard_live`.
- No schema change.
