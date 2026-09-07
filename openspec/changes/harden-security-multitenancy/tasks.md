## 1. Migration & Duplicate Report

- [x] 1.1 Add duplicate-report task — create `mix treby.detect_duplicate_emails` (read-only query grouping active candidates by `tenant_id, lower(email)` having count > 1); verify `mix treby.detect_duplicate_emails` runs and reports 0 groups on a clean dev DB.
- [x] 1.2 Create unique-index migration — run `mix ecto.gen.migration add_candidates_tenant_email_unique_active` adding partial unique index `(tenant_id, lower(email)) WHERE merged_into_id IS NULL`; verify `mix ecto.migrate` + `mix ecto.rollback --step 1` + `mix ecto.migrate` round-trip on dev.

## 2. Context — Race-Safe `create_or_find`

- [x] 2.1 Rewrite `Candidates.create_or_find/2` (`lib/treby/candidates.ex`) with `insert(on_conflict: :nothing)` + re-read fallback; verify `mix test test/treby/candidates_test.exs` green.
- [x] 2.2 Add concurrency regression test — `Task.async_stream` 10 parallel creates with same tenant/email, assert single candidate; run `mix test test/treby/candidates_test.exs`.

## 3. Context — Search & Uploads Hardening

- [x] 3.1 Add `escape_like/1` in `Candidates.Queries` and use it in `apply_search` (`lib/treby/candidates/queries.ex`), job search (`lib/treby/jobs/jobs.ex:41,55`), audit search (`lib/treby/audit.ex:174`); verify `%`/`_` match literally via `mix test test/treby/candidates_test.exs test/treby/jobs_test.exs test/treby/audit_test.exs`.
- [x] 3.2 Enforce `scoped_key` in `Treby.Uploads` — thread `tenant_id` through `upload_file`, `get_presigned_url`, `delete_file` (`lib/treby/uploads.ex`) and update call sites (`careers_live/apply.ex:363`, `settings_live/branding.ex:169`, `resume_controller.ex:17`); verify `mix test test/treby/uploads_test.exs` green.

## 4. Rate Limiting & Audit Attribution

- [x] 4.1 Add `Hammer` dep + `Treby.RateLimit` wrapper — add `{:hammer, "~> 6.0"}` to `mix.exs`, `config :treby, :rate_limits` defaults in `config/config.exs` with env overrides; verify `mix deps.get && mix compile --warnings-as-errors`.
- [x] 4.2 Throttle login + OTP endpoints — wire `RateLimit.check` into `SessionController.create/2` and `CandidateOtpController.create/verify` (429 + localized flash on deny); verify existing auth/OTP tests still pass.
- [x] 4.3 Propagate `ip`/`user_agent` — add `Audit.attrs_from_conn/1` and use it in `SessionController`, `CandidateOtpController`, and pipeline `move_application` LiveView path; verify `mix test test/treby/audit_test.exs` green.
- [x] 4.4 Add `mix treby.rotate_cloak_key` task and CSRF regression test for `DELETE /:slug/portal/logout`; verify `mix test test/treby_web/integration/candidate_portal_security_test.exs` green.

## 5. LiveView/UI

- [x] 5.1 Wire 429 feedback in login/OTP templates — ensure throttled responses render the localized retry message with `id="rate-limit-error"` for testability; no `site/` changes (no user-manual behavior change beyond error text).

## 6. Tests

- [x] 6.1 Run full suite `mix test` and fix regressions; ensure 531+ tests green with zero warnings.

## 7. Specs & Docs Sync

- [x] 7.1 Sync main specs — merge delta specs from `openspec/changes/harden-security-multitenancy/specs/**` into `openspec/specs/{candidate-management,authentication,candidate-otp-auth,file-upload,candidate-search,job-search,audit-log}/spec.md` and ensure `openspec validate --strict` passes; confirm `site/` needs no update (no new user-facing capability).
- [x] 7.2 Run `mix precommit` and `openspec validate --strict` and fix all issues (format, credo, sobelow, translations, design-system guard).
