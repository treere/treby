## Why

Treby processes personal data for candidates and team users as a processor on behalf of tenant controllers. GDPR Articles 15 (access), 17 (erasure), and 20 (portability) require self-service data export and erasure, both executed asynchronously with time-limited download and auditable completion. Without this, tenants cannot honor data-subject requests within the 30-day deadline and Treby risks non-compliance.

## What Changes

- **Async data export**: any authenticated team user can request a full export of their own data; tenant admins can request a tenant-scoped export (users, candidates, applications, notes, interviews, messages, resumes). Request creates a `data_privacy_requests` row with state `pending → processing → ready → expired`, enqueues an Oban worker that builds a ZIP (JSON + original files) in S3, and exposes a presigned download URL valid 7 days with email notification.
- **Async erasure (right to be forgotten)**: user self-deletion and tenant/company deletion (admin-only, with confirmation + 7-day grace/undo window). Erasure is async via Oban, uses anonymization (not hard FK-breaking delete) for candidates/applications to preserve referential integrity, purges S3 objects (resumes, logos), and anonymizes audit metadata containing PII.
- **Request tracking & audit**: every Data & Privacy request is logged with requester, scope, status, timestamps, and completion is audited via `audit_events`; admins can list their tenant's Data & Privacy requests.
- **Retention & expiry**: export packages auto-expire after 7 days (S3 delete + status `expired`); completed erasures are retained as request records but PII is gone.
- **BREAKING**: `mix ecto.gen.migration create_data_privacy_requests` adds `data_privacy_requests` table; no existing columns renamed.

## Capabilities

### New Capabilities
- `data-privacy-export`: async generation, packaging, and time-limited download of personal/tenant data
- `data-privacy-erasure`: async anonymization/purge for user and tenant scope with grace period
- `data-privacy-requests`: lifecycle, listing, and audit of Data & Privacy requests

### Modified Capabilities
- `audit-log`: add `data_privacy.*` actions (`data_privacy.export_requested`, `data_privacy.export_ready`, `data_privacy.export_downloaded`, `data_privacy.erasure_requested`, `data_privacy.erasure_completed`, `data_privacy.erasure_cancelled`) and PII anonymization rule for audit metadata on erasure
- `candidate-management`: candidate anonymization behavior on erasure (name/email/phone/linkedin/custom_fields nulled or hashed, applications retained anonymized)

## Impact

- **Migrations**: `create_data_privacy_requests` (id uuid v7, tenant_id, requester_id, type `export|erasure`, scope `user|tenant`, status, s3_key, expires_at, completed_at, metadata jsonb)
- **Modules**: new `lib/treby/data_privacy/*` (requests context, export builder, anonymizer), new `lib/treby/workers/data_privacy_export_worker.ex` + `data_privacy_erasure_worker.ex`, updates to `lib/treby/candidates.ex`, `lib/treby/accounts/accounts.ex`, `lib/treby/tenants/tenants.ex`, `lib/treby/audit.ex`, `lib/treby/uploads.ex` (scoped helpers already exist)
- **LiveViews**: new `SettingsLive.DataPrivacy` at `/:tenant/app/settings/data-privacy` (admin) + personal section in `SettingsLive.Index` / user menu for self-export/delete
- **Deps**: no new deps (reuse Oban, ExAws S3, Req); config `config :treby, data_privacy_export_bucket` reuses S3 bucket with `data-privacy-exports/` prefix
- **Docs**: new `site/features/data-privacy.md` + sidebar entry
