# Data Privacy Requests

## Purpose

Track lifecycle, listing, and audit of every data export and erasure request in a tenant-scoped `data_privacy_requests` table.

## Requirements

### Requirement: Data & Privacy request lifecycle and listing
The system SHALL store every export/erasure request in `data_privacy_requests` with `id, tenant_id, requester_id, type, scope, status, s3_key, expires_at, completed_at, metadata, error, inserted_at, updated_at` and expose a tenant-scoped listing. Status transitions SHALL be `pending → processing → ready|completed|failed` (export: `ready → expired`; erasure: `pending → completed|cancelled`).

#### Scenario: Admin lists tenant requests
- **WHEN** an admin visits `/:tenant/app/settings/data_privacy`
- **THEN** they see all `data_privacy_requests` for that tenant ordered by `inserted_at desc` with filters by `type` and `status`

#### Scenario: User lists own requests
- **WHEN** a member views their personal Data & Privacy section
- **THEN** they see only requests where `requester_id = current_user.id`

#### Scenario: Tenant isolation
- **WHEN** querying `data_privacy_requests`
- **THEN** every query requires `tenant_id` and never returns rows from another tenant

### Requirement: Request status visibility and polling
The system SHALL show real-time status for each request (pending/processing/ready/expired/completed/failed) and auto-refresh via LiveView PubSub or polling until terminal state.

#### Scenario: Status updates live
- **WHEN** a worker transitions a request to `ready`
- **THEN** the UI updates without full page reload to show the download button

