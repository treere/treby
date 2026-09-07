## Why

Treby is multi-tenant and internet-facing (public career pages, candidate portal, staff login) but lacks basic abuse and concurrency defenses: `Candidates.create_or_find/2` does read-then-insert without a unique index (duplicate race under concurrent applies), staff login (`SessionController.create/2`) and OTP request endpoints have no IP/email throttling (only a 60s per-candidate OTP cooldown), S3 keys are tenant-prefixed by convention but never validated, and `ilike` search interpolates `%`/`_` wildcards verbatim. Fixing these now closes the highest-risk 🔴 items before scale, pagination, and public exposure grow.

## What Changes

- Add partial unique index `candidates_tenant_email_unique_active` on `(tenant_id, lower(email))` where `merged_into_id IS NULL` via `mix ecto.gen.migration`, and make `Candidates.create_or_find/2` race-safe with `insert(on_conflict: :nothing)` + re-read (fallback to existing record on conflict).
- Add request rate limiting with `Hammer` (new dep `{:hammer, "~> 6.0"}`): staff login `POST /login` (e.g. 5 req/min/IP + 10/hour per email), portal OTP request `POST /:slug/portal/login` and verify `POST /:slug/portal/verify` (e.g. 5 req/min/IP + per-email cap), returning 429 with `Retry-After` and a localized flash/JSON error; keep the existing 60s OTP cooldown.
- Enforce tenant-scoped S3 keys: call `Treby.Uploads.scoped_key(tenant_id, key)` inside `upload_file/3` and `get_presigned_url/2` so non-prefixed keys raise; verify the two current call sites (`careers_live/apply.ex` resumes, `settings_live/branding.ex` logos) already pass `"#{tenant_id}/..."` keys and fix any that do not.
- Add `escape_like/1` (in `Treby.Candidates.Queries` or new `Treby.Search`) escaping `%`, `_`, `\` and use it in candidate search (`queries.ex`), job search (`jobs.ex`), and audit-log search (`audit.ex`); `%`/`_` typed by users match literally.
- Propagate `ip`/`user_agent` on `Audit.log_event` from web entry points: add `Audit.attrs_from_conn(conn)` helper (peer IP + user-agent header) and use it in `SessionController`, `CandidateOtpController`, and `Applications.move_application` LiveView call path where a conn/socket is available; schema already supports both columns.
- Add `mix treby.rotate_cloak_key` MIX task + runbook note for `CLOAK_KEY` rotation (`lib/treby/vault.ex`).
- Verify CSRF coverage for `DELETE /:slug/portal/logout` (already under `:browser` pipeline with `protect_from_forgery`): add a regression test asserting 403/redirect without token rather than changing code if covered.

## Capabilities

### New Capabilities
- _None_ — this change hardens existing capabilities without adding user-facing features.

### Modified Capabilities
- `candidate-management`: Duplicate-email upsert (`create_or_find`) SHALL be safe under concurrent requests — a second concurrent insert with the same tenant/email returns the existing active candidate instead of creating a duplicate (DB unique index + `on_conflict` handling).
- `authentication`: Staff login SHALL be rate-limited per IP and per email; excess attempts receive HTTP 429 (or a login error with retry guidance) instead of hitting credential verification.
- `candidate-otp-auth`: OTP request and verify endpoints SHALL be throttled per IP (in addition to the existing 60s per-candidate cooldown); excess requests are rejected with a "too many requests, retry later" message.
- `file-upload`: S3 operations SHALL reject keys not prefixed with the caller's tenant id (`scoped_key` enforcement); storage paths and validation otherwise unchanged.
- `candidate-search`: Search input containing `%` or `_` SHALL match those characters literally instead of acting as wildcards.
- `job-search`: Same literal handling of `%`/`_` in job title/description/location search.
- `audit-log`: Web-triggered audit events SHALL include request `ip` and `user_agent` when the call originates from a conn/socket (already shown in the admin view when present).

## Impact

- **Modules:** `lib/treby/candidates.ex` (`create_or_find`), `lib/treby/candidates/queries.ex` (`escape_like`), `lib/treby/jobs/jobs.ex`, `lib/treby/audit.ex` (+ `attrs_from_conn/1`), `lib/treby/uploads.ex` (enforce `scoped_key`), `lib/treby_web/controllers/session_controller.ex`, `lib/treby_web/controllers/candidate_otp_controller.ex`, `lib/treby/candidate_portal/candidate_portal.ex` (throttle hooks), new `lib/treby/rate_limit.ex` (Hammer wrapper) + `lib/mix/tasks/treby.rotate_cloak_key.ex`, `config/config.exs` (Hammer backend config), `priv/repo/migrations/*_add_candidates_tenant_email_unique_active.exs`.
- **APIs:** No route changes; login/OTP endpoints return 429 under abuse; `Uploads.upload_file/get_presigned_url` raise `ArgumentError` on non-tenant keys (call sites already compliant — verified, not changed).
- **Dependencies:** Add `{:hammer, "~> 6.0"}` (ETS backend, no Redis needed for single node; document Redis switch for multi-node in design).
- **Migrations:** One (`mix ecto.gen.migration add_candidates_tenant_email_unique_active`): partial unique index; backfill check for existing duplicates required before deploy (design covers detection query + merge-first strategy).
- **Config:** `config :hammer` backend; rate-limit thresholds via `config :treby, :rate_limits` with env overrides.
- **Risks:** Existing duplicate (tenant,email) rows would block the migration — mitigated by a pre-migration duplicate report task and `auto_merge_exact_email` runbook step.
