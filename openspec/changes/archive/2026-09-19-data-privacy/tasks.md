## 1. Migration & Schema

- [x] 1.1 Generate migration `mix ecto.gen.migration create_data_privacy_requests` with `data_privacy_requests` table (id uuid v7, tenant_id uuid FK, requester_id uuid FK, type text, scope text, status text, s3_key text, expires_at utc_datetime, completed_at utc_datetime, metadata jsonb default `{}`, error text, timestamps) + indexes on `(tenant_id, status)` and `expires_at` + partial unique on `(tenant_id, type, scope, requester_id)` where status in ('pending','processing') — verify `mix ecto.migrate` / `mix ecto.rollback --step 1`
- [x] 1.2 Create `lib/treby/data_privacy/data_privacy_request.ex` schema + changeset (validations for type/scope/status enums, tenant_id required, s3_key only for export) and `lib/treby/data_privacy/requests.ex` context (`create_request`, `get_request!`, `list_requests`, `transition`, `cancel`) with tenant-scoped queries — verify `mix test` for changeset

## 2. Export & Erasure Core

- [x] 2.1 Implement `Treby.DataPrivacy.ExportBuilder` (pure) that streams tenant/user data (users, candidates, applications with snapshot, notes, interviews, scorecards, messages, notifications prefs) into `export.json` + collects S3 keys (resumes/logos) for the ZIP
- [x] 2.2 Implement `Treby.DataPrivacy.Anonymizer` with `anonymize_candidate/1`, `anonymize_user/1`, `anonymize_audit_metadata/2`, and `purge_s3_objects/2` helpers (idempotent, batch 100, via `Repo.stream`)
- [x] 2.3 Create `Treby.Workers.DataPrivacyExportWorker` (queue: default, max 3) — `pending→processing→ready` (upload ZIP to `#{tenant_id}/data-privacy-exports/#{id}.zip` via `Treby.Uploads`), set `expires_at`, emit `data_privacy.export_ready` audit, send Swoosh email; on error set `failed`
- [x] 2.4 Create `Treby.Workers.DataPrivacyErasureWorker` (queue: default, grace check `grace_until`) — `pending→completed` via `Ecto.Multi` per batch, S3 deletes, audit scrub, email notify; handle `last_admin` guard and `cancelled` short-circuit
- [x] 2.5 Add expiry/cleanup: Oban cron module or `GdprExpiry` function + `Treby.DataPrivacy.Requests.expire_ready/0` that deletes S3 objects for `ready && expires_at <= now` and emits `data_privacy.export_expired`

## 3. LiveView & Controller UI

- [x] 3.1 Create `TrebyWeb.DataPrivacy` / `SettingsLive.data_privacy` at `/:tenant/app/settings/data_privacy` (admin-only via `RequireRole admin`) with request list (filter by type/status), new export (scope toggle), new erasure (tenant slug confirm), cancel, and download button — tenant-isolated, streams for list
- [x] 3.2 Add personal Data & Privacy section to `SettingsLive.Index` (or user menu) for `user` scope self-export/self-erasure (any role) + status polling via PubSub
- [x] 3.3 Create `TrebyWeb.DataPrivacyDownloadController` `GET /data-privacy/exports/:id/download` — checks `status==ready && expires_at>now`, verifies `tenant_id` match via `scoped_key/2`, generates **signed URL** via `Treby.Uploads.get_presigned_url(tenant_id, s3_key, expires_in: 3600)`, returns 302 to signed URL (never proxy file), logs `data_privacy.export_downloaded` audit; else 410/403 — verify signed URL is tenant-scoped and expires in 1h (test asserts key prefix `tenant_id/data-privacy-exports/` and no direct S3 key leak in HTML)
- [x] 3.4 Wire router: add `live "/settings/data-privacy", DataPrivacy` under `:admin` live_session, `get "/data-privacy/exports/:id/download"` under `:require_auth`, and `choose-tenant` guard for grace-blocked logins (plug checks `tenant.settings["data_privacy_pending_erasure"]`)

## 4. Audit & S3 Hardening

- [x] 4.1 Extend `Treby.Audit` to emit `data_privacy.*` events and implement `anonymize_audit_for_erasure(tenant_id, erased_ids)` that scrubs `metadata` PII fields
- [x] 4.2 Add tests: `test/treby/data_privacy/requests_test.exs` (tenant isolation, duplicate pending reject), `test/treby/workers/data_privacy_export_worker_test.exs` + `data_privacy_erasure_worker_test.exs` (happy path, idempotency, S3 mocked via bypass), `test/treby_web/live/gdpr_live_test.exs` (admin vs member, download auth) — verify `mix test test/treby/data_privacy/`

## 5. Specs & Docs

- [x] 5.1 Sync specs to main: copy `openspec/changes/data-privacy/specs/data-privacy-export/spec.md` → `openspec/specs/data-privacy-export/spec.md`, same for `data-privacy-erasure` and `data-privacy-requests`; merge delta specs into `openspec/specs/audit-log/spec.md` and `openspec/specs/candidate-management/spec.md` — verify `openspec validate --strict`
- [x] 5.2 Create `site/features/data-privacy.md` (English only, user manual: where to find `Settings → Data & Privacy`, how to request export/erasure, download window, grace cancel) + update `site/features/index.md` and sidebar in `site/.vitepress/config.ts`; regenerate screenshots with `node scripts/screenshots.mjs` (captures both themes) and include Data & Privacy pages
- [x] 5.3 Run `mix precommit` and `openspec validate --strict` and fix issues

