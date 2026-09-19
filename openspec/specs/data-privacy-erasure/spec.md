# Data Privacy Erasure

## Purpose

Provide async, grace-period erasure with anonymization (not hard delete) for user and tenant scope, preserving FK integrity while scrubbing PII and S3 files.

## Requirements

### Requirement: Async erasure request with grace period
The system SHALL allow users to request erasure of their own user data (`scope=user`) and admins to request erasure of the entire tenant (`scope=tenant`). Each request SHALL create a `data_privacy_requests` row with `type=erasure`, `status=pending`, `metadata.grace_until = now + 7 days`, enqueue an Oban worker, and allow cancellation until grace expires. Tenant erasure SHALL require typing the tenant slug as confirmation.

#### Scenario: User requests self-erasure
- **WHEN** an authenticated user requests erasure with scope `user`
- **THEN** a request is created with `requester_id = current_user.id` and a worker is enqueued but does not execute until `grace_until` passes

#### Scenario: Admin requests tenant erasure with confirmation
- **WHEN** an admin requests tenant erasure and correctly confirms the tenant slug
- **THEN** the request is created, all admins receive an email, and logins for that tenant are blocked with a grace notice until completion or cancellation
- **AND** a non-admin or wrong slug yields permission/validation error

### Requirement: Tenant erasure is admin-only
The system SHALL allow tenant-scope erasure (Delete company) only to admin members because it anonymizes/deletes company-wide data and requires 7-day grace and slug confirmation, while user-scope erasure (Delete my account) SHALL be available to any authenticated member for their own data.

#### Scenario: Member erases own account
- **WHEN** a member requests erasure with `scope=user`
- **THEN** the erasure is created for that user's own data

#### Scenario: Member cannot erase company data
- **WHEN** a member requests erasure with `scope=tenant`
- **THEN** the system returns an error flash "Only admins can erase company data" and no tenant erasure is created

#### Scenario: Admin erases company data with correct slug
- **WHEN** an admin requests erasure with `scope=tenant` and `confirm` equals the tenant slug
- **THEN** the tenant erasure is created with 7-day grace

#### Scenario: Admin erasure with wrong slug is rejected
- **WHEN** an admin requests erasure with `scope=tenant` and `confirm` does not match the tenant slug
- **THEN** the system returns an error flash "Confirmation does not match company slug"

#### Scenario: Cancel within grace
- **WHEN** the requester (or any admin for tenant scope) cancels before `grace_until`
- **THEN** status becomes `cancelled`, the worker is discarded, and `data_privacy.erasure_cancelled` is audited

### Requirement: Anonymization execution
The system SHALL, after grace expiry, anonymize PII instead of hard-deleting to preserve FK integrity: candidates (`name → "Deleted Candidate <short_id>"`, `email → "deleted+<id>@deleted.local"`, `phone/linkedin → nil`, `custom_fields → {}`, `notification_preferences → {}`), applications (snapshot overwritten, `resume_url → nil`, S3 resume deleted), users (name/email hashed, `password_hash` randomized, memberships removed), and tenant settings scrubbed. S3 objects SHALL be deleted via `Treby.Uploads.delete_file/2`.

#### Scenario: Candidate anonymized on tenant erasure
- **WHEN** tenant erasure executes
- **THEN** every candidate in the tenant is anonymized per above and every `resume_url` S3 object is deleted
- **AND** applications remain as anonymized rows (no hard delete)

#### Scenario: Last admin protection
- **WHEN** a user erasure would leave the tenant with zero admins
- **THEN** the request is rejected with `{:error, :last_admin}` and no anonymization occurs

### Requirement: Audit and notification on erasure
The system SHALL emit `data_privacy.erasure_requested` on creation and `data_privacy.erasure_completed` on success, and send email notifications to affected users and admins.

#### Scenario: Erasure completed audited
- **WHEN** the erasure worker finishes anonymization
- **THEN** it sets `status = completed`, `completed_at = now`, and inserts audit event `data_privacy.erasure_completed` with `tenant_id` and `actor_id`

### Requirement: Erasure is idempotent and tenant-isolated
The system SHALL scope all erasure queries by `tenant_id` and make the worker idempotent (re-running on already-anonymized rows is a no-op).

#### Scenario: Re-run is safe
- **WHEN** the worker retries after partial failure
- **THEN** already-anonymized candidates are skipped and remaining ones are processed

