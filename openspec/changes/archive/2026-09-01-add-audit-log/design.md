## Context

Treby already has `activity_log` (`lib/treby/activities/*`, `priv/repo/migrations/*_create_activity_log.exs`) used for the candidate timeline (`lib/treby_web/live/candidates_live/show.ex:98`, `lib/treby/dashboard.ex:140`). It is entity-scoped, informal, and driven by ad-hoc `Treby.Activities.log_event/4` calls in ~10 contexts. There is no guarantee that every state change is recorded, no `before`/`after` diff, no `actor_type` or request metadata (`ip`, `user_agent`), and no admin-only browsable audit view. Tenant isolation is present but not formally specified as an audit requirement.

Stakeholders: workspace admins (compliance, incident review), members (operational trust), and the system itself (debugging). The change must be tenant-isolated, role-gated, immutable, and low-overhead.

## Goals / Non-Goals

**Goals:**
- Immutable, append-only audit trail covering all state-changing domain actions with `before`/`after` diffs.
- Tenant isolation enforced at context and query layer; admin-only UI with filters and pagination.
- Minimal performance overhead; transactional consistency where the audited mutation and audit write must succeed or fail together.
- Reuse existing `current_scope` (`%{user, tenant}`) for actor/tenant attribution without new auth primitives.

**Non-Goals:**
- Candidate-portal visibility — audit log stays admin-only.
- Real-time streaming or PubSub for audit events (polling/pagination is sufficient).
- Full-text search or analytics aggregation over audit events (defer).
- Automatic backfill of historical events before the feature ships.
- PII expansion — no raw secrets, no CV content, no email bodies in audit metadata.

## Decisions

**D1: New `audit_events` table vs extending `activity_log`**
- Chosen: new `audit_events` table. `activity_log` is optimized for candidate timeline display (entity_type `candidate`/`application`, free-form `metadata`, preloaded `actor`). Overloading it with job/pipeline/team/auth events would pollute the timeline and complicate retention. A dedicated table allows stricter immutability (no updates/deletes via context), indexed `action`/`entity_type`, and independent retention policy.
- Alternative: add columns to `activity_log` — rejected due to mixed concerns and migration risk.

**D2: Schema shape**
- `audit_events`: `id` (binary_id), `tenant_id` FK `tenants` `delete_all`, `actor_id` FK `users` `nilify_all` (nullable for `system`/`candidate` actions), `actor_type` enum string (`user`|`candidate`|`system`), `action` string (namespaced `resource.verb` e.g., `job.updated`, `application.stage_moved`, `pipeline.stage_reordered`), `entity_type` + `entity_id`, `metadata` JSONB (`before`/`after`, `actor_email` snapshot, `request_id`), `ip` (`:string`), `user_agent` (`:string`), `inserted_at` only (no `updated_at`; updates disallowed).
- Indexes: `(tenant_id)`, `(tenant_id, inserted_at)`, `(entity_type, entity_id)`, `(actor_id)`, `(action)`.
- Rationale: `tenant_id` mandatory and indexed for isolation; `before`/`after` diff is the audit value — generic `metadata` JSONB keeps schema stable across 15+ entity types.

**D3: Context API contract**
- `Treby.Audit` context: `log_event(action, entity_type, entity_id, attrs)` where `attrs` includes `tenant_id` (required), `actor_id`, `actor_type`, `metadata`, `ip`, `user_agent`. Returns `{:ok, event}` / `{:error, changeset}`.
- `log_event_multi(multi, name, action, entity_type, entity_id, attrs)` helper for `Ecto.Multi` to make mutation + audit atomic (`Repo.transaction`).
- `list_events(tenant_id, opts)` with filters: `actor_id`, `action` (prefix match), `entity_type`, `entity_id`, `from`/`to` (utc), `search` (action/entity), `page`/`page_size`. All queries scope `where tenant_id == ^tenant_id`. Preload `actor`.
- Caching: none — audit reads are infrequent, strongly consistent, and must reflect latest writes.
- Error handling: audit insert failures do **not** silently swallow the primary mutation when using `Multi`; non-`Multi` callers log via `Logger.warning` and return error but do not roll back already-committed mutations. Doc the caller choice.

**D4: Instrumentation points**
- Centralize audit calls at the context boundary (the function that already does `Repo.insert/update/delete` or `Multi`), not in LiveViews or controllers, to guarantee coverage regardless of entry point (UI, bulk, CSV, portal). Cover: `Treby.Candidates`, `Treby.Jobs`, `Treby.Pipeline` (stages/pipelines/templates/roles), `Treby.Applications`/`Pipeline.move_application`, `Treby.Notes`, `Treby.Interviews`, `Treby.Scorecards`, `Treby.Messages`/`Notifications`, `Treby.Team`/`Memberships`/`Invites`, `Treby.Tenants`/`Branding`, `Treby.CustomFields`, `Treby.Sources`, `Treby.Accounts` (login).
- For `before`/`after`, capture `Ecto.Changeset` diff or `previous = Repo.preload` snapshot before update; store only changed fields + identifiers, redacting secrets.

**D5: Authorization & multi-tenancy**
- All audit writes require `tenant_id`; writes without tenant raise. Reads require `tenant_id` and `current_scope` role check — only `admin` can `list_events` via web; context function itself enforces tenant scoping but not role (role checked in LiveView `on_mount`/`handle_params`).
- Portal and public career page never expose audit endpoints.

**D6: UI**
- New LiveView `Settings.AuditLogLive` at `/:company/app/settings/audit-log` (admin pipeline). Uses `<Layouts.app flash={@flash} current_scope={@current_scope}>`, `LiveView` streams for rows, `<.input>` for filters, `FilterBar` + `Card` + `Badge` from `TrebyWeb.DesignSystem`. Filters: date range (from/to), actor dropdown, action prefix, entity type, entity search. Paginated (page_size 25). Detail drawer/modal shows `before`/`after` diff.
- Failure mode: if audit query fails, show `Feedback` error, do not block other settings pages.

## Risks / Trade-offs

- **Write amplification** → Every mutation adds one insert. Mitigation: single-row insert, no extra queries beyond diff capture; no PubSub broadcast for audit events; batch bulk moves one event per application (still O(n) but n ≤ 50 typical).
- **PII in metadata** → Accidentally logging secrets/CV content. Mitigation: explicit allow-list per `action` for `before`/`after` fields; shared helper `Audit.sanitize_metadata/2` that drops `:password`, `:token`, `:resume_url` body, and truncates long strings.
- **Inconsistent coverage** → Missed call sites. Mitigation: checklist in `tasks.md` per context; add `mix treby.check_audit_coverage` dev check (grep for `Repo.insert|update|delete` without sibling `Audit.log` in same function) as follow-up, not required for v1.
- **Immutable table growth** → Unbounded growth. Mitigation: BRIN index on `inserted_at`, pagination, and deferred retention purge job (Oban) — spec requires retention policy but v1 ships as "retain indefinitely" with manual purge documented.
- **Transaction coupling** → `Multi` makes audit failure roll back business mutation. Mitigation: document when to use `Multi` (critical compliance actions like `member role change`) vs best-effort `log_event` after commit (low-critical like `note_created`).

## Migration Plan

1. Generate migration `mix ecto.gen.migration add_audit_events` creating `audit_events` table with indexes above.
2. Deploy: `mix ecto.migrate` — no data backfill; new events only from deploy forward.
3. Add `Treby.Audit` context and LiveView route (behind admin auth); existing `activity_log` untouched.
4. Incrementally wire audit calls per context; each is independently shippable.
5. Rollback: `mix ecto.rollback`; audit reads degrade to empty state with no impact on business tables. No down-migration data loss beyond audit rows.

## Open Questions

- Should `bulk move` produce one aggregate event with `metadata.application_ids` or one per application? Decision: one per application for filterability, with shared `batch_id` in metadata to correlate.
- Should candidate portal actions (OTP verify, self-schedule) be audited as `actor_type: candidate`? Decision: yes, but only for actions that mutate hiring state (self-schedule, message reply), not for pure reads.
