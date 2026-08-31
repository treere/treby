## 1. Migration & Schema

- [x] 1.1 Generate migration `mix ecto.gen.migration add_audit_events` creating `audit_events` table with columns `id` binary_id PK, `tenant_id` FK tenants `delete_all` NOT NULL, `actor_id` FK users `nilify_all`, `actor_type` string NOT NULL default `user`, `action` string NOT NULL, `entity_type` string NOT NULL, `entity_id` binary_id NOT NULL, `metadata` map JSONB default `%{}`, `ip` string, `user_agent` string, `inserted_at` utc_datetime, plus indexes on `tenant_id`, `tenant_id+inserted_at`, `entity_type+entity_id`, `actor_id`, `action`, `inserted_at` — verify `mix ecto.migrate` and `mix ecto.rollback` clean
- [x] 1.2 Create `Treby.Audit.AuditEvent` schema (`lib/treby/audit/audit_event.ex`) with binary_id, belongs_to tenant/actor, changeset validating required `tenant_id`, `action`, `entity_type`, `entity_id`, `actor_type` inclusion, and forbidding `updated_at` handling

## 2. Audit Context

- [x] 2.1 Implement `Treby.Audit` (`lib/treby/audit.ex`): `log_event/4` (attrs: `tenant_id` required, `actor_id`, `actor_type`, `metadata` with `before`/`after`, `ip`, `user_agent`), `log_event_multi/6` for `Ecto.Multi`, `list_events/2` with filters `actor_id`, `action` prefix, `entity_type`, `entity_id`, `from`/`to`, `search`, pagination `page`/`page_size` (default 25), tenant-scoped queries, `preload :actor`, plus `sanitize_metadata/2` allow-list helper per action
- [x] 2.2 Add context helpers to inject `current_scope` → `tenant_id`/`actor_id`/`ip`/`user_agent` cleanly from LiveView/controller `conn`, and unit tests for `Treby.Audit` (insert, immutability, tenant isolation, filtering, pagination)

## 3. Instrumentation — Hiring & Applications

- [x] 3.1 Wire audit in `Treby.Candidates` and `Treby.Applications`/`Treby.Pipeline.move_application`: candidate create/update/merge, application create/stage_move/bulk_move/reject, with `before`/`after` diff capture
- [x] 3.2 Wire audit in `Treby.Notes`, `Treby.Interviews`, `Treby.Scorecards`, `Treby.Messages`/`Treby.Notifications`: note create, interview schedule/cancel/complete, scorecard submit/update, message send/schedule

## 4. Instrumentation — Configuration & Team

- [x] 4.1 Wire audit in `Treby.Jobs`, `Treby.Pipeline` (pipelines/stages/templates/roles + `min_examiners`), `Treby.Tenants` branding/settings, `Treby.CustomFields`, `Treby.Sources`: CRUD + reorder/role assignments with diff sanitization
- [x] 4.2 Wire audit in `Treby.Team`/`Treby.Memberships`/`Treby.Accounts`: invite create/accept, membership role change/remove, auth login/workspace_switch, and candidate portal mutations (OTP verify, conversation reply, self-schedule) with `actor_type: candidate` where applicable

## 5. LiveView & Routing

- [x] 5.1 Create admin-only `TrebyWeb.Settings.AuditLogLive` at `/:company/app/settings/audit-log` wrapped with `<Layouts.app flash={@flash} current_scope={@current_scope}>`, using streams (`phx-update="stream"`), `DesignSystem.Card`/`Badge`/`FilterBar`, `<.input>` filters (date range, actor, action prefix, entity type, entity search), pagination, and detail drawer/modal rendering `before`/`after` diff + `ip`/`user_agent`; add route in `lib/treby_web/router.ex` behind admin `on_mount`
- [x] 5.2 Add settings nav entry for Audit Log and enforce role gate (member redirect with flash), plus tenant isolation assertion for the view

## 6. Tests

- [x] 6.1 Add LiveView tests for `AuditLogLive` (admin sees paginated tenant-scoped events, filters work, detail shows diff; member redirected; cross-tenant isolation)
- [x] 6.2 Add integration tests per instrumented context verifying audit rows are created with correct `action`/`entity`/`actor_type`/`before`/`after` and tenant scoping, including `Ecto.Multi` atomicity case and `candidate` actor case — run `mix test <paths>`
- [x] 6.3 Add immutability/PII guard tests (update/delete rejected, secrets not persisted)

## 7. Specs & Docs Sync

- [x] 7.1 Update main specs: copy `openspec/changes/add-audit-log/specs/audit-log/spec.md` to `openspec/specs/audit-log/spec.md` (new capability with Purpose/Requirements), and apply deltas to `openspec/specs/activity-log/spec.md` and `openspec/specs/role-based-access/spec.md` per change specs — verify `openspec validate --strict`
- [x] 7.2 Sync docs (no new `site/features/*.md` per AGENTS.md — audit log is admin compliance detail excluded from user manual; optionally add one-line note in `site/architecture.md` without file paths/module names if needed)

## 8. Final Verification

- [x] 8.1 Run `mix precommit` and `openspec validate --strict` and fix all issues
