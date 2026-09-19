## ADDED Requirements

### Requirement: Async data export request
The system SHALL allow authenticated users to request an async data export for `user` scope (own data) and admins to request `tenant` scope (all tenant data). Each request SHALL create a `data_privacy_requests` record with `type=export`, `status=pending`, and enqueue an Oban worker.

#### Scenario: User requests own export
- **WHEN** an authenticated user requests an export with scope `user`
- **THEN** a `data_privacy_requests` row is created with `requester_id = current_user.id`, `tenant_id = current_tenant.id`, `status = pending`
- **AND** an Oban job `DataPrivacyExportWorker` is enqueued

#### Scenario: Admin requests tenant export
- **WHEN** an admin requests an export with scope `tenant`
- **THEN** the system creates the request only if `current_membership.role == "admin"`
- **AND** non-admins receive a permission-denied error

#### Scenario: Duplicate pending export rejected
- **WHEN** a `pending` or `processing` export already exists for the same `(tenant_id, scope, requester_id)` tuple
- **THEN** the new request is rejected with `{:error, :already_pending}`

### Requirement: Export package generation
The system SHALL generate a ZIP package containing `export.json` (users, candidates, applications, notes, interviews, scorecards, messages, notifications preferences) plus original S3 files (resumes, logos) scoped to the request, upload it to S3 at `#{tenant_id}/data-privacy-exports/#{request_id}.zip`, and transition the request to `ready` with `expires_at = now + 7 days`.

#### Scenario: Worker builds tenant export
- **WHEN** `DataPrivacyExportWorker` processes a tenant-scoped request
- **THEN** it streams all tenant candidates/applications/notes/interviews/messages, writes `export.json`, copies S3 objects to a temp dir, zips, uploads to S3, and updates `status = ready`, `s3_key`, `expires_at`
- **AND** on failure it sets `status = failed` with `error` and will retry up to 3 times

#### Scenario: Tenant isolation enforced
- **WHEN** building the export
- **THEN** every query filters by `tenant_id = request.tenant_id`
- **AND** no data from other tenants is included

### Requirement: Time-limited download with notification
The system SHALL expose a download endpoint that returns a **signed (presigned) S3 URL** valid 1 hour only while `status == ready` and `expires_at > now`, logs `data_privacy.export_downloaded` to audit, and sends an email notification when the package becomes ready. The signed URL SHALL be generated via `Treby.Uploads.get_presigned_url(tenant_id, s3_key, expires_in: 3600)` which enforces `scoped_key/2` (key must start with `#{tenant_id}/`) and never streams the file through the app. After 7 days the package SHALL be deleted from S3 and status set to `expired`.

#### Scenario: Download while valid
- **WHEN** the requester (or admin for tenant scope) hits `GET /data-privacy/exports/:id/download` while ready and not expired
- **THEN** the system verifies `request.tenant_id == current_tenant.id` and `s3_key` is tenant-scoped, generates a presigned URL with 3600s expiry, returns 302 to that URL, and logs an audit event
- **AND** the S3 object is never proxied; the app only issues the signed URL and the client fetches directly from S3

#### Scenario: Download after expiry rejected
- **WHEN** `expires_at <= now` or status is `expired`
- **THEN** the download returns 410 Gone and no URL is issued

#### Scenario: Expiry cleanup
- **WHEN** the daily expiry job runs
- **THEN** every `ready` request with `expires_at <= now` has its S3 object deleted and status set to `expired`

### Requirement: Export audit trail
The system SHALL emit audit events `data_privacy.export_requested` on creation, `data_privacy.export_ready` on completion, and `data_privacy.export_downloaded` on download, each with `tenant_id`, `actor_id`, and `metadata` containing `request_id` and `scope`.

#### Scenario: Export requested audited
- **WHEN** an export request is created
- **THEN** an audit event `data_privacy.export_requested` is inserted

