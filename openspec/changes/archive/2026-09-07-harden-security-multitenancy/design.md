## Context

After the `refactor-architecture-quality` change, `Candidates.create_or_find/2` lives in `lib/treby/candidates.ex:44` (read-then-insert, no lock), analytics/duplicates are modular, and `Treby.Uploads.scoped_key/2` exists but is not enforced. The app is internet-facing: public career/apply pages, candidate portal (OTP), staff login. Current defenses: 60s per-candidate OTP cooldown (`candidate_portal.ex:44`), audit `ip`/`user_agent` columns supported but rarely populated (`audit.ex:94` builds only tenant/actor), plain (non-unique) candidate email index (`20260714103413_create_candidates.exs:18`).

Stakeholders: security-minded self-hosters, candidates (OTP abuse → email bombing), staff (credential stuffing on `/login`).

## Goals / Non-Goals

**Goals:**
- Make concurrent candidate creation duplicate-free at the DB level.
- Throttle authentication endpoints per IP/email with 429 semantics.
- Fail-closed S3 key scoping and literal search semantics.
- Attribute audit events to request IP/agent from web entry points.

**Non-Goals:**
- No CAPTCHA, WebAuthn, or SSO (separate changes).
- No per-tenant S3 buckets (key-prefix scoping only).
- No Redis-backed distributed limiting (single-node ETS; multi-node documented as follow-up).
- No changes to OTP code format/expiry or password policy.

## Decisions

**Decision 1: Partial unique index + constraint-violation fallback for `create_or_find`**
- Migration: `create unique_index(:candidates, ["tenant_id", "lower(trim(email))"], where: "merged_into_id IS NULL AND nullif(trim(email), '') IS NOT NULL", name: :candidates_tenant_email_unique_active)` (blank emails excluded so address-less candidates can never collide). `Candidate.changeset/2` maps it via `unique_constraint(:email, name: ...)`. Rewrite `create_or_find/2` as: normalize email → fast-path `Repo.one` → on miss, plain `create_candidate` → on `{:error, changeset}` carrying that constraint name, re-read the active candidate and return `{:ok, winner}` (fallback to the error if re-read finds nothing).
- *Rationale:* DB is the only correct arbiter under concurrency. Plain insert + mapped violation was chosen over `on_conflict: :nothing` because the arbiter for a partial expression index cannot be expressed in Ecto (`ON CONFLICT` would need a `WHERE` predicate Ecto doesn't support); the fallback only triggers on real races. Partial index excludes tombstoned rows so merges/undo keep working.
- *Alternative considered:* `FOR UPDATE` advisory lock per email — rejected, adds lock contention and complexity across nodes; unique index is simpler and total.

**Decision 2: Hammer ETS backend behind a `Treby.RateLimit` wrapper**
- New `Treby.RateLimit.check(bucket_key, scale, limit)` returning `:allow | {:deny, retry_after_ms}` wrapping `Hammer.check_rate/3`. Plugs/controllers call it with keys like `{"login:ip", ip}`, `{"login:email", email}`, `{"otp:req:ip", ip}`, `{"otp:req:email", email}`. Limits via `config :treby, :rate_limits` (defaults: login 5/min/IP, 10/hour/email; OTP request 5/min/IP, 5/hour/email; OTP verify 10/min/IP). Denied HTML requests re-render with 429 status + localized "too many requests" flash; API-style/JSON (if any) get `Retry-After` header.
- *Rationale:* Hammer 6 ETS backend needs no infra; wrapper centralizes key naming, config, and test seam (Mox-free: wrapper reads backend from config so tests use a stub).
- *Alternative:* `PlugAttack` — rejected, Hammer has simpler per-key API and smaller footprint; `ex_rated` — rejected, unmaintained.

**Decision 3: Enforce (not just provide) `scoped_key`**
- `upload_file/3` and `get_presigned_url/2` call `scoped_key(tenant_id, key)` — but they don't receive `tenant_id` today. Change signatures to `upload_file(tenant_id, key, content, content_type)`? That breaks call sites. Instead: validate prefix shape `"<uuid-or-slug>/..."`? Weaker. Decision: add `tenant_id` as first arg to both functions and update the 3 call sites (`careers_live/apply.ex:363`, `settings_live/branding.ex:169-170`, `resume_controller.ex:17` read-only presign — pass tenant from conn/socket). `delete_file/1` → `delete_file(tenant_id, key)` likewise. Raising `ArgumentError` on violation = fail-closed.
- *Rationale:* Convention-only scoping already produced tenant-prefixed keys at call sites; enforcement at the boundary makes it impossible to regress. Explicit arg beats regex-guessing tenant formats.
- *Alternative:* keep signatures, validate `key` contains `/` — rejected, doesn't prove ownership.

**Decision 4: `escape_like/1` in `Candidates.Queries`, reused by Jobs and Audit**
- `escape_like(s)` replaces `\` → `\\`, `%` → `\%`, `_` → `\_` and queries add `escape: "\\"`: `ilike(c.name, ^pattern, escape: "\\")`. Ecto/Postgres support `ESCAPE`. One implementation, three call sites.
- *Rationale:* Single place to extend (e.g. full-text later); fixes wildcard injection without changing "contains" semantics for normal input.
- *Alternative:* `Treby.Search` module — rejected, overkill for one function; Queries already owns candidate search.

**Decision 5: `Audit.attrs_from_conn/1` + threading through LiveView**
- New `attrs_from_conn(conn)` returns `%{ip: to_string(:inet.ntoa(peer_ip)), user_agent: get_req_header("user-agent")}` merged with `attrs_from_scope(current_scope)`. Controllers pass it to `log_event`. For `move_application` (called from LiveViews without conn), accept `opts[:audit]` passthrough and have pipeline LiveViews build attrs from `socket` (`get_connect_info` peer data is limited; use `socket.assigns.current_scope` + stored connect IP if available, else actor-only as today). No schema change.
- *Rationale:* Works with existing columns and admin UI (already renders ip/agent when present); graceful degradation where no conn exists.
- *Alternative:* mandatory ip on all events — rejected, background jobs/Oban have no request context.

**Decision 6: Cloak rotation as MIX task + docs, CSRF as test-only**
- `mix treby.rotate_cloak_key` re-encrypts vault columns with old+new key from env (`OLD_CLOAK_KEY`, `CLOAK_KEY`), printing a runbook checklist. CSRF: `DELETE /:slug/portal/logout` already pipes through `:browser` (`protect_from_forgery`) — add regression test, no code change expected.

## Risks / Trade-offs

- **Existing duplicate emails block migration** → Mitigation: `mix treby.detect_duplicate_emails` report task (read-only) run before migrate; runbook orders `auto_merge_exact_email` first; migration uses `validate: false` + `validate_index` concurrently? (Ecto `create index(..., concurrently: true)` needs `disable_ddl`; keep simple: report-then-merge-then-migrate, documented).
- **Hammer ETS resets on restart / per-node** → Mitigation: acceptable for single-node self-host (documented); limits are abuse-dampening, OTP cooldown remains the hard gate; multi-node Redis noted as follow-up.
- **`Uploads` signature change breaks 3 call sites + tests** → Mitigation: compiler finds all callers (update all in one commit); presigned-URL tests updated.
- **429 on shared office IPs** → Mitigation: per-email bucket is the tighter gate for login (10/hour is generous); IP bucket set to 5/min to allow normal use; flashes explain retry.
- **Audit PII in user-agent** → Mitigation: existing `sanitize_metadata` truncates; ip/agent columns are plain (already schema-approved, shown in admin view).

## Migration Plan

1. Ship `escape_like`, `attrs_from_conn`, `RateLimit` wrapper + controller wiring (no migration; safe to deploy alone).
2. Deploy unique-index migration in a maintenance window after running duplicate-report + auto-merge; `create_or_find` rewrite ships in the same release (old code works with new index; new code works without it, falling back to re-read).
3. Enforce `scoped_key` (signature change) with call-site updates + tests.
4. Rotation task + CSRF regression test (additive).
5. Rollback: revert commits; index drops with `mix ecto.rollback` (single migration); Hammer removal = delete dep + wrapper (controllers fall back to unthrottled — acceptable temporary).

## Open Questions

- Exact OTP throttle numbers (5/min/IP + 5/hour/email proposed) — confirm against current email-delivery abuse baseline; tunable via config without code change.
- Should `verify` attempts also decrement per-candidate `attempts` (exists, max 5) — yes, keep; IP throttle is additive.
