## Why

Hiring decisions need accountability. Treby logs key candidate activities (`activity_log`) for the profile timeline, but there is no immutable, tenant-isolated audit trail covering all system changes (job edits, pipeline config, stage moves, scorecards, interviews, messages, team invites, settings). Admins cannot answer "who changed what, when, and what was the previous value?" for compliance, incident review, or simple operational trust. Adding an audit log closes this gap.

## What Changes

- Introduce an immutable, append-only audit log (`audit_events` table) separate from the existing `activity_log` (which remains the candidate-facing timeline). Audit events are never updated or deleted by application code.
- Record audit events for all state-changing actions: candidate/application CRUD, job CRUD and publish/unpublish, pipeline/stage create/update/delete/reorder, stage role assignments, application stage moves (including bulk), notes/ratings, interviews (schedule/cancel/complete), scorecards (create/update), messages (send/schedule), team invites/member role changes/removals, tenant branding/settings, custom fields, sources, and authentication events (login, workspace switch).
- Each event stores: `tenant_id`, `actor_id` (nullable for system/portal actions), `actor_type` (`user` | `candidate` | `system`), `action` (e.g., `job.updated`), `entity_type` + `entity_id`, `metadata` JSONB with `before`/`after` diff (PII-safe, no raw secrets), `ip`/`user_agent` when available, and `inserted_at`.
- Provide context helpers (`Treby.Audit`) with `log_event/4` and transactional variants (`log_event_multi/4` via `Ecto.Multi`) plus automatic tenant/actor injection from `current_scope`.
- Add admin-only Audit Log view under `/:company/app/settings/audit-log` (and optionally filterable timeline on relevant detail pages) with filters by date range, actor, action, entity, and pagination; tenant-isolated queries enforced at the context layer.
- Add retention and privacy: immutable storage, no user-facing delete, optional scheduled purge after configurable retention (default: retain indefinitely), excluded from candidate portal.
- Write DB migration via `mix ecto.gen.migration add_audit_events`.

## Capabilities

### New Capabilities
- `audit-log`: immutable tenant-isolated audit trail for all state-changing actions, with storage schema, context API, and admin UI (filters, pagination, detail view) plus retention rules.

### Modified Capabilities
- `activity-log`: keep as candidate-facing timeline but clarify it is a filtered presentation layer derived from / complementary to audit events; no requirement change except to avoid duplication and to document that audit-log is the source of truth for compliance.
- `role-based-access`: extend to gate audit log view to `admin` role only (members cannot access).
- `dashboard`: optional entry point/link to audit log from settings; no metric change.

## Impact

- Dependencies: none new (uses `Ecto`, `PostgreSQL` JSONB, `Phoenix.LiveView`; no external services).
- Code: new `lib/treby/audit/*` (schema `AuditEvent` + context `Treby.Audit`), new LiveView `lib/treby_web/live/settings/audit_log_live.ex` + components, updates to ~15 contexts to emit audit events (`lib/treby/candidates/*`, `lib/treby/jobs/*`, `lib/treby/pipeline/*`, `lib/treby/interviews/*`, `lib/treby/scorecards/*`, `lib/treby/notes/*`, `lib/treby/team/*`, `lib/treby/tenants/*`, `lib/treby/custom_fields/*`), `lib/treby_web/router.ex` route, `lib/treby_web/components/layouts.ex` nav.
- Migrations: `priv/repo/migrations/*_add_audit_events.exs` (table `audit_events` with indexes on `tenant_id`, `entity_type+entity_id`, `actor_id`, `action`, `inserted_at`).
- Build/deploy: no config change; excluded from candidate portal; covered by `mix precommit` and existing tenant-isolation guards.
- Docs: no `site/` user-manual page required (admin-only compliance feature per AGENTS.md — implementation detail); optionally mention in `site/architecture.md` at high level without file paths.
