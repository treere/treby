## ADDED Requirements

### Requirement: Data & Privacy audit events
The system SHALL emit namespaced audit events for every Data & Privacy lifecycle transition: `data_privacy.export_requested`, `data_privacy.export_ready`, `data_privacy.export_downloaded`, `data_privacy.erasure_requested`, `data_privacy.erasure_completed`, `data_privacy.erasure_cancelled`, `data_privacy.export_expired`. Each event SHALL include `tenant_id`, `actor_id`, `entity_type="data_privacy_request"`, `entity_id=request.id`, and `metadata` with `type` and `scope`.

#### Scenario: Data & Privacy events appear in audit log
- **WHEN** any Data & Privacy transition occurs
- **THEN** an `audit_events` row with the corresponding `data_privacy.*` action is inserted and visible to admins at `/:tenant/app/settings/audit-log` filtered by action prefix `data_privacy.`

## MODIFIED Requirements

### Requirement: Immutable audit event storage
The system SHALL store every state-changing action as an immutable audit event scoped to a tenant. Audit events SHALL be append-only and never updated or deleted by application code, with the sole exception of PII anonymization during Data & Privacy erasure which SHALL scrub `actor` display names and `metadata` fields containing emails/names for erased subjects.

#### Scenario: Audit event created on state change
- **WHEN** a state-changing action occurs (e.g., candidate updated, application stage moved, job published)
- **THEN** an audit event is inserted with `tenant_id`, `actor_id` (or null for system), `actor_type` (`user`|`candidate`|`system`), `action` (namespaced `resource.verb`), `entity_type`, `entity_id`, `metadata` containing `before`/`after` diff, `ip`/`user_agent` when available, and `inserted_at`

#### Scenario: Audit events are immutable
- **WHEN** an audit event has been created
- **THEN** no application code path updates or deletes it except the Data & Privacy anonymization path which overwrites PII in `metadata` and denormalized actor fields
- **AND** the row has no `updated_at` and any other update attempt is rejected at the context layer

#### Scenario: Tenant isolation enforced
- **WHEN** audit events are written or queried
- **THEN** `tenant_id` is required and all queries filter by `tenant_id`
- **AND** events from one tenant are never visible to another tenant

#### Scenario: Data & Privacy erasure scrubs PII in audit
- **WHEN** a Data & Privacy erasure completes for a user or tenant
- **THEN** audit events where `actor_id` or `entity_id` matches an erased subject have `metadata` fields containing `email`/`name` replaced with anonymized values and `actor` display is shown as "Deleted User"
