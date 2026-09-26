## Why

Tenant isolation relies on handwritten `where tenant_id == ^...` filters scattered across every context (~50 sites) plus manual portal guards. One forgotten filter leaks cross-tenant data. Following the Ecto "Multi tenancy with foreign keys" guide, the repository itself SHALL enforce scoping so unscoped queries fail loudly instead of silently exposing data.

## What Changes

- `Treby.Repo.prepare_query/3` auto-applies `where tenant_id == ^tenant` to every query whose schema carries a `tenant_id` field, taking the tenant from the process dictionary or an explicit `tenant_id:` option.
- `Treby.Repo.default_options/1` injects the process-dictionary tenant into all operations; missing tenant on a tenant-field query raises unless `skip_tenant_id: true` is passed explicitly.
- `Treby.Repo.put_tenant_id/1` called on every entry point: web plug (controllers), `RequireMembership` on_mount (LiveViews), each Oban worker from job args, seeds and test setup.
- Existing manual `where tenant_id` filters stay (harmless redundancy, defense in depth); new code omits them.
- Schemas without a `tenant_id` field (tenants table itself, users pre-onboarding with nil tenant, join/globals) bypass scoping; cross-table joins keep working because inserts always write matching ids (composite foreign keys as follow-up, out of scope here).

## Capabilities

### New Capabilities
- `tenant-scoped-queries`: repository-enforced tenant scoping with explicit opt-out, covering reads, writes, and bulk operations.

### Modified Capabilities
- (none — no user-observable behavior changes; previously-correct queries return identical results)

## Impact

- Modules: `Treby.Repo` (`prepare_query`, `default_options`, `put/get_tenant_id`), `RequireMembership` plug + hook (put on entry), 5 Oban workers (put from args), `DataCase`/`ConnCase` setup, seeds.
- Risks: `Task.async` processes do not inherit the process dictionary — code inside async tasks must receive an explicit `tenant_id:` option (audited in design); public career/portal pages set the tenant from slug before querying.
- No migrations. No schema changes. No new dependencies.
