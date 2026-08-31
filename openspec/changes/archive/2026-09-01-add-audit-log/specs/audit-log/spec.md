## ADDED Requirements

### Requirement: Immutable audit event storage
The system SHALL store every state-changing action as an immutable audit event scoped to a tenant. Audit events SHALL be append-only and never updated or deleted by application code.

#### Scenario: Audit event created on state change
- **WHEN** a state-changing action occurs (e.g., candidate updated, application stage moved, job published)
- **THEN** an audit event is inserted with `tenant_id`, `actor_id` (or null for system), `actor_type` (`user`|`candidate`|`system`), `action` (namespaced `resource.verb`), `entity_type`, `entity_id`, `metadata` containing `before`/`after` diff, `ip`/`user_agent` when available, and `inserted_at`

#### Scenario: Audit events are immutable
- **WHEN** an audit event has been created
- **THEN** no application code path updates or deletes it
- **AND** the row has no `updated_at` and any update attempt is rejected at the context layer

#### Scenario: Tenant isolation enforced
- **WHEN** audit events are written or queried
- **THEN** `tenant_id` is required and all queries filter by `tenant_id`
- **AND** events from one tenant are never visible to another tenant

### Requirement: Comprehensive action coverage
The system SHALL emit audit events for all auditable domain actions across hiring, configuration, and team management.

#### Scenario: Hiring actions audited
- **WHEN** any of the following occurs: candidate created/updated/merged, application created/stage moved (single or bulk)/rejected, note created, interview scheduled/cancelled/completed, scorecard created/updated, message sent/scheduled, source/custom-field linked
- **THEN** a corresponding audit event is created with action `candidate.created`, `application.stage_moved`, `note.created`, `interview.scheduled`, `scorecard.submitted`, `message.sent`, etc., and metadata includes before/after identifiers and changed fields

#### Scenario: Configuration actions audited
- **WHEN** a job is created/updated/published/unpublished, a pipeline or stage is created/updated/deleted/reordered, stage roles or `min_examiners` are changed, a pipeline template is applied, branding/settings are changed, custom fields or sources are created/updated/deleted
- **THEN** an audit event is created with action `job.updated`, `pipeline.stage_reordered`, `stage.roles_assigned`, `tenant.branding_updated`, `custom_field.created`, etc.

#### Scenario: Team and auth actions audited
- **WHEN** a team invitation is created/accepted, a membership role is changed or a member is removed, a user logs in or switches workspace
- **THEN** an audit event is created with action `team.invite_created`, `membership.role_changed`, `auth.login`, `auth.workspace_switched`

#### Scenario: Candidate portal mutations audited
- **WHEN** a candidate verifies OTP, replies to a conversation, or self-schedules an interview
- **THEN** an audit event is created with `actor_type: candidate` and the candidate's id as `actor_id`

### Requirement: Before/after diff with PII safety
The system SHALL record a `before`/`after` diff in `metadata` for update actions, redacting secrets and limiting PII to changed fields.

#### Scenario: Update stores diff
- **WHEN** an entity is updated
- **THEN** `metadata.before` and `metadata.after` contain only the changed fields plus primary identifiers
- **AND** secrets (`password`, `token`, OTP) and large blobs (CV file content, email bodies) are never stored

#### Scenario: Create stores after snapshot
- **WHEN** an entity is created
- **THEN** `metadata.after` contains the created identifiers and key attributes, and `metadata.before` is null or empty

#### Scenario: Delete stores before snapshot
- **WHEN** an entity is deleted
- **THEN** `metadata.before` contains the deleted entity's identifiers and key attributes for traceability

### Requirement: Context API and transactional consistency
The system SHALL provide a central `Treby.Audit` context for logging and querying audit events with transactional support.

#### Scenario: Direct log via context
- **WHEN** `Treby.Audit.log_event(action, entity_type, entity_id, attrs)` is called with `tenant_id` and optional `actor_id`/`actor_type`/`metadata`/`ip`/`user_agent`
- **THEN** it inserts the audit event and returns `{:ok, event}` or `{:error, changeset}`

#### Scenario: Transactional log via Ecto.Multi
- **WHEN** a state change is performed inside an `Ecto.Multi`
- **THEN** `Treby.Audit.log_event_multi(multi, name, action, entity_type, entity_id, attrs)` can be used so the mutation and audit insert succeed or fail atomically

#### Scenario: Query with filters and pagination
- **WHEN** `Treby.Audit.list_events(tenant_id, opts)` is called with filters `actor_id`, `action` (prefix), `entity_type`, `entity_id`, `from`/`to` (UTC), and pagination `page`/`page_size` (default 25)
- **THEN** it returns tenant-scoped events ordered by `inserted_at` desc with `actor` preloaded
- **AND** queries without `tenant_id` are rejected

### Requirement: Admin-only audit log view
The system SHALL provide an admin-only audit log view at `/:company/app/settings/audit-log` with filters, pagination, and detail inspection.

#### Scenario: Admin can view audit log
- **WHEN** an admin navigates to `/:company/app/settings/audit-log`
- **THEN** the page loads and shows paginated audit events for that tenant with filters for date range, actor, action, entity type, and entity search

#### Scenario: Member cannot view audit log
- **WHEN** a member navigates to the audit log route
- **THEN** the system redirects to the dashboard with a permission-denied flash (consistent with `role-based-access` admin-only settings)

#### Scenario: Event detail shows diff
- **WHEN** an admin clicks an audit event row
- **THEN** a detail drawer/modal shows `action`, `actor` (name/email or "System"), `entity`, `timestamp`, and rendered `before`/`after` diff
- **AND** the request `ip` and `user_agent` are shown when present

#### Scenario: Tenant isolation in UI
- **WHEN** an admin views the audit log for tenant A
- **THEN** no events from tenant B are ever returned, even if the admin has membership in both tenants — the view is scoped to the current workspace `tenant_id`

### Requirement: Retention and access boundaries
The system SHALL treat audit events as long-term compliance data, exclude them from the candidate portal, and define a retention policy.

#### Scenario: Audit log excluded from portal
- **WHEN** a candidate is authenticated in the portal
- **THEN** no audit log endpoint or UI is accessible to them

#### Scenario: No user-facing delete
- **WHEN** any user attempts to delete an audit event via the UI or context
- **THEN** the operation is not offered and is rejected if attempted

#### Scenario: Retention policy documented
- **WHEN** the system is deployed
- **THEN** audit events are retained indefinitely by default, with a documented manual purge procedure (future Oban retention job may delete events older than a configurable window, but is not required for v1)
