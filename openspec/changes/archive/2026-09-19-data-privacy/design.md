## Context

Treby is multi-tenant ATS where `tenant_id` scopes every table. Personal data lives in Postgres (users, candidates, applications, notes, interviews, scorecards, messages, notifications, audit_events) and S3 (resumes, logos). Existing `delete_*` helpers are synchronous hard deletes; audit log is append-only. Oban is already in use (`messages` and `default` queues) and S3 access is via `Treby.Uploads` with tenant-scoped keys. There is no Data & Privacy request lifecycle, no export builder, and no anonymization strategy. Stakeholders: data subjects (candidates, team users), tenant admins (controllers), Treby operator (processor).

## Goals / Non-Goals

**Goals:**
- Async export and erasure for `user` and `tenant` scopes satisfying Art. 15/17/20 with 7-day download window and auditable lifecycle
- Anonymize-instead-of-delete to keep FK integrity and reporting continuity
- Tenant-isolated, role-gated, idempotent workers with retry and expiry

**Non-Goals:**
- Candidate self-service via portal OTP (future; tenant admin handles candidate erasure via candidate anonymize)
- Consent management / legal-basis tracking, retention auto-purge for candidates, cookie banner, RoPA/Breach/DPA — deferred to follow-up changes
- Per-field encryption or per-tenant export bucket — reuse existing S3 bucket with `data-privacy-exports/` prefix

## Decisions

**Decision: Single `data_privacy_requests` table + state machine**
- Columns: `id uuid v7`, `tenant_id`, `requester_id`, `type enum[export,erasure]`, `scope enum[user,tenant]`, `status enum[pending,processing,ready,expired,completed,cancelled,failed]`, `s3_key`, `expires_at`, `completed_at`, `metadata jsonb`, `error`, timestamps. Index on `(tenant_id, status)` and `expires_at`.
- Alternative considered: separate tables per type — rejected, lifecycle identical, single table simplifies listing/audit.

**Decision: Two Oban workers, no new queue**
- `DataPrivacyExportWorker` (queue: default, max_attempts 3) and `DataPrivacyErasureWorker` (queue: default). Reuse existing Oban setup; no infra change.
- Export builds JSON (`export.json` with users/candidates/applications/notes/interviews/messages) + copies S3 files into temp dir, zips, uploads to `#{tenant_id}/data-privacy-exports/#{request_id}.zip`, sets `expires_at = now+7d`, sends email via Swoosh.
- Erasure worker runs inside `Ecto.Multi` per scope: for `user` scope anonymize `users` row + null memberships; for `tenant` scope iterate candidates/users/jobs in batches (100) anonymizing, deleting S3 objects via `Treby.Uploads.delete_file/2`, then optionally soft-delete tenant after grace. Each step logs `audit_events` with `actor_type: user`.

**Decision: Anonymization over hard delete**
- Candidate: `name → "Deleted Candidate #{hash}"`, `email → "deleted+#{id}@deleted.local"`, `phone/linkedin → nil`, `custom_fields → {}`, `merged_into_id` preserved. Applications kept with `anagrafica_snapshot` overwritten to anonymized values. Resumes deleted from S3, `resume_url` nulled.
- User: `name/email` hashed, `password_hash` randomized, `memberships` removed; if last admin, require transfer.
- Tenant erasure: after anonymizing all children, set `tenants.settings["data_privacy_erased_at"]` and revoke sessions; hard `DELETE FROM tenants` only after 7-day grace if not cancelled.
- Alternative: hard delete everything — rejected, breaks audit FKs and analytics.

**Decision: Tenant isolation & authorization**
- Every query filters `tenant_id = current_tenant.id`. Export `tenant` scope requires `current_membership.role == "admin"`; `user` scope allowed for any authenticated user (own data) and admin for any user in tenant. Erasure `tenant` scope admin-only + double confirmation (type tenant slug). Checked in LiveView `on_mount :require_role` and context `with_tenant/2` guard.

**Decision: Expiry & cleanup + Signed URL**
- `DataPrivacyExportWorker` sets `expires_at`; daily `GdprExpiry` via Oban cron (`0 3 * * *`) deletes expired S3 objects and flips status to `expired`. Download **MUST use signed URL only** — controller checks `status == ready && expires_at > now`, verifies `tenant_id` match, then calls `Treby.Uploads.get_presigned_url(tenant_id, s3_key, expires_in: 3600)` which enforces `scoped_key/2` (key prefixed `tenant_id/data-privacy-exports/...` or raises). App returns 302 to signed URL; file never proxied through Phoenix. Signed URL TTL 1h, package TTL 7d. Alternative (stream through app) rejected: OOM + no S3 offload.

**Decision: No provider abstraction**
- No behaviour/resolver needed — export builder is single module `Treby.DataPrivacy.ExportBuilder` with pure functions `build_json(tenant_id, scope)`; erasure is `Treby.DataPrivacy.Anonymizer`.

## Risks / Trade-offs

- **Large tenant export OOM** → Mitigation: stream DB via `Repo.stream` + write JSONL, zip on disk in `/tmp`, upload via streaming; cap at 10k candidates v1, document limit
- **S3 eventual consistency / delete failure** → Mitigation: idempotent delete, log `failed_s3_keys` in `metadata`, retry via worker `backoff`, manual re-run button
- **Audit log PII leakage after erasure** → Mitigation: on erasure, run `UPDATE audit_events SET metadata = anonymized_metadata WHERE tenant_id=^tid AND (actor_id IN ^erased_ids OR entity_id IN ^erased_ids)` stripping emails/names
- **Tenant erasure grace abuse** → Mitigation: 7-day `cancelled` window, email to all admins on request + on cancel, prevent new logins during grace via plug check `tenant.settings["data_privacy_pending_erasure"]`
- **Concurrent export/erasure** → Mitigation: unique Oban job per `(tenant_id, type, scope)` pending/processing, DB unique index on `(tenant_id, type, scope)` where status in `[pending,processing]`

## Migration Plan

1. Deploy migration `create_data_privacy_requests` (no downtime, new table)
2. Deploy code (workers + LiveView + controller) behind no flag — menu hidden until migration applied
3. Backfill: none
4. Rollback: drop table, remove workers; anonymized rows not reversible — document in runbook

## Open Questions

- ZIP password protection? v1 no — presigned URL + auth gate sufficient; add optional password later.
- Email template for export-ready/erasure-scheduled — reuse existing `EmailTemplates` or new Swoosh template?
- Should tenant erasure also purge `webhook_subscriptions` and `ai_conversations`? Yes for v1 (list in anonymizer).
