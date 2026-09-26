## Context

`Treby.Repo` is a bare `Ecto.Repo` with no callbacks. 33 schemas carry `belongs_to :tenant`; 9 do not: `tenants/tenant` itself, child/join tables reached only through parents (`pipeline_stage`, `stage_examiner/reviewer/advancer`, `event_examiner`, `candidate_portal/message`), and pre-auth user-scoped tokens (`password_reset_token`, `registration_otp`). Bulk writes (`update_all`/`delete_all` in `bulk_operations`, `anonymizer`, `accounts`, `authorization`) target tenant-field schemas. The only `Task.async` use is the health check. 5 Oban workers run outside any request process. Following the Ecto "Multi tenancy with foreign keys" guide (`prepare_query` + `default_options` + process-dictionary tenant), enforcement lands in the repository instead of ~50 handwritten filters.

## Goals / Non-Goals

**Goals:**
- Every query against a tenant-field schema is scoped, with the tenant from an explicit option or the process dictionary; anything else raises.
- All entry points establish the tenant: web pipeline, LiveViews, Oban workers, seeds, tests.
- Pre-auth and global paths keep working via explicit, auditable opt-outs.

**Non-Goals:**
- Removing existing manual `where tenant_id` filters (defense in depth, zero risk to keep).
- Composite foreign keys (`with:`) for cross-table guarantees — follow-up change.
- Changing context function signatures; the tenant flows beside existing arguments.

## Decisions

**1. Scope only schemas that have the field; raise otherwise.**
`prepare_query` inspects the query source schema: no `tenant_id` field → pass through untouched (covers `tenants`, join tables, pre-auth tokens without needing opt-outs everywhere). Field present → apply `where tenant_id == ^tenant` with tenant from `opts[:tenant_id]` or the process dictionary; neither and no `skip_tenant_id: true` → raise. Alternative (raise for every unscoped query including field-less schemas) would force meaningless opt-outs on global tables. The 9 field-less schemas were enumerated by grep; the task list includes re-verifying the enumeration.

**2. Tenant enters the process at the same place identity does.**
Web: a plug sets it from the resolved tenant (slug or session) for controllers; `RequireMembership.on_mount` sets it for LiveViews (each LiveView is its own process). Oban: each of the 5 workers calls `put_tenant_id` from job args at the top of `perform` — workers never inherit a request process. Tests/seeds set it explicitly in setup. Alternative (passing `tenant_id:` through every context call) re-creates the scattering this change removes.

**3. Async boundary: explicit option, no magic.**
`Task.async` does not inherit the process dictionary. The only current use (health check) passes `skip_tenant_id: true` explicitly. Any future async Repo use must take an explicit `tenant_id:` option — enforced by the raise, which is the point.

**4. Land enforcement directly, fix the fallout in the same change.**
A log-only mode would double the machinery for a transition lasting one change. Migration plan: implement callbacks → run the full suite → every raise names its call site → fix by establishing the tenant (preferred) or explicit `skip_tenant_id` with a comment (pre-auth tokens, health check, global admin paths). Rollback is a revert of `repo.ex` plus entry-point calls; no migrations involved.

## Risks / Trade-offs

- [Risk] Third-party or Ecto-internal queries hitting tenant-field schemas without tenant set → Mitigation: `:ecto_query` opt-outs for `:schema_migration`/`:preload` per the guide; suite run exposes the rest.
- [Risk] `prepare_query` does not scope joins inside a query → Mitigation: accepted (same as the guide); inserts always write matching ids, composite FKs are the follow-up.
- [Risk] Forgotten `put_tenant_id` in a new worker/entry point fails closed (raise) rather than leaking → Mitigation: this is the desired direction; loud failure beats silent leak.
- [Trade-off] Manual filters stay duplicated → accepted: redundancy here is defense in depth, removal would be churn across ~50 sites.
