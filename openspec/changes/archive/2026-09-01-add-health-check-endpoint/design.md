## Context

Treby is a Phoenix 1.8 + LiveView ATS deployed as a self-hostable Elixir/Bandit application with PostgreSQL and S3-compatible object storage (RustFS locally, ExAWS in production). There is currently no unauthenticated HTTP endpoint that external orchestrators can poll without going through the browser pipeline, session, CSRF, or tenant resolution. `TrebyWeb.Router` defines browser, API, and auth pipelines but no health route; `TrebyWeb.Endpoint` terminates Plug.Static, parsers, session and then delegates to the router. Kubernetes liveness/readiness probes, Docker `HEALTHCHECK`, and load-balancer health checks require a fast, unauthenticated, tenant-agnostic `200 OK` response.

Stakeholders: platform/SRE (k8s manifests, Helm), backend (Elixir app), no end-user impact.

Constraints: must not expose sensitive data, must not require `tenant_slug`, must work before any DB query succeeds (liveness), and must optionally verify downstream dependencies for readiness without adding new dependencies.

## Goals / Non-Goals

**Goals:**
- Provide an unauthenticated `GET /health` (liveness) that returns `200` as soon as the BEAM is serving HTTP, with minimal overhead.
- Provide an alias `GET /healthz` for k8s convention compatibility.
- Provide a readiness endpoint `GET /health/ready` that checks PostgreSQL (and optionally S3) and returns `200` when ready / `503` when degraded, with a JSON body describing each check.
- Ensure the endpoint bypasses `:browser` pipeline (no session, CSRF, `RequireMembership`, `SetLocale`) and has no tenant isolation requirement.
- Response must be JSON, `content-type: application/json`, include `status`, and be cache-busted (`Cache-Control: no-store`).

**Non-Goals:**
- No metrics endpoint (`/metrics` / Prometheus) — separate concern.
- No authenticated or tenant-scoped health data.
- No UI, LiveView, or documentation site (`site/`) changes.
- No DB migrations or new environment variables.
- No rate limiting or auth for the health route (it is intentionally open and cheap).

## Decisions

**Decision 1 — Route placement: dedicated unauthenticated scope in `TrebyWeb.Router` + optional `Endpoint` fast-path**
- Implement `TrebyWeb.HealthController` (plain `Phoenix.Controller`, no layout) and mount it in `TrebyWeb.Router` inside a new `scope "/", TrebyWeb` with `pipe_through []` (or minimal `:api`-like pipeline without auth) for `/health`, `/healthz`, and `/health/ready`.
- Alternative considered: plug directly in `TrebyWeb.Endpoint` before `Plug.Session` for earliest response and to avoid router compilation. Rejected as primary mechanism because router is the idiomatic place for a documented HTTP contract and tests via `ConnTest` connect to the router; Endpoint plug would bypass `Plug.Telemetry`/`Plug.RequestId` that we want to keep. A minimal router pipeline preserves observability while still avoiding session/CSRF overhead. Optional future optimization: add a tiny `TrebyWeb.Plugs.HealthCheck` at the top of `Endpoint` if latency measurement shows router overhead matters — design keeps controller stateless so it can be moved without contract change.
- Rationale: stays consistent with existing public routes (`/`, `/careers`, `/login`) which use `pipe_through :browser` vs. public unauthenticated scopes; health is another public unauthenticated scope, just without browser plugs.

**Decision 2 — Endpoints and semantics (k8s alignment)**
- `GET /health` — liveness: always returns `200` if process is up. Body: `{"status":"ok"}` (plus optional `uptime`/`version` later, but not required for v1).
- `GET /healthz` — alias to `/health` (same controller action) for compatibility with k8s examples/docs.
- `GET /health/ready` — readiness: checks `Treby.Repo` with a lightweight query (`SELECT 1` via `Ecto.Adapters.SQL.query/2` or `Repo.query("SELECT 1")`) with short timeout (2s). Returns `200 {"status":"ok","checks":{"database":"ok"}}` when DB is reachable, else `503 {"status":"error","checks":{"database":"error"}}`. S3/RustFS check is optional and best-effort: if `ExAWS`/`S3` config is present, a `head_bucket` or `list_buckets` with 2s timeout; if S3 is not configured, report `"skipped"` rather than failing readiness (avoids false negatives in dev without S3). Parallel aggregation with `Task.async` + `Task.await` and overall 3s budget; fail-closed on timeout/error for DB, fail-open (skipped) for S3.
- Alternatives: single `/health?ready=true` query param. Rejected — two distinct paths are clearer for k8s `livenessProbe` vs `readinessProbe` and allow different handlers/timeouts without param parsing.

**Decision 3 — Response format and headers**
- JSON only, `application/json`. No HTML negotiation. Explicit `Cache-Control: no-store, no-cache, must-revalidate` and `Pragma: no-cache` to avoid caching by probes or CDNs.
- Status field is `"ok"` vs `"error"` (string) to keep body self-describing even if HTTP status is stripped by a proxy. No PII, no tenant data, no stack traces.

**Decision 4 — Error handling and caching strategy**
- Liveness: never touches DB or external services — cannot fail due to downstream. Any exception returns `500` (BEAM crash path) which k8s interprets as not-live.
- Readiness: each check wrapped in `try/rescue` + `Task.yield` timeout. DB check failure → `503` with `checks.database = "error"` and `error` string (sanitized, no raw exception leaked). S3 check timeout/error → `"error"` only if S3 is required (env flag); default `"skipped"`. No caching — every probe hits the live check. Parallel aggregation via `Task.async_stream` or `Task.async`+`await` with `timeout: 2000` per check; overall controller timeout handled by Bandit request timeout (default 30s) but we cap at 3s internally.
- Fail-closed for DB (readiness must reflect DB down), fail-open/skipped for S3 (storage degradation should not block readiness unless explicitly required).

**Decision 5 — Tenant isolation and authorization**
- Health endpoints are tenant-agnostic and intentionally bypass `RequireMembership`/`RequireRole`. They SHALL NOT require `tenant_slug` and SHALL NOT filter by `tenant_id`. This is a deliberate exception to the multi-tenant rule, documented in the spec. No `current_scope` assign is set.

**Decision 6 — Observability**
- Keep `Plug.RequestId` and `Plug.Telemetry` (via `Endpoint`) so health probes appear in logs/metrics with request IDs. No custom Telemetry event for v1; reuse `[:phoenix, :endpoint, :stop]` duration.

## Risks / Trade-offs

- **Unauthenticated surface** → Mitigation: endpoint is read-only, returns no sensitive data, no DB content, rate is low (probe interval 10-30s). Optionally restrict via k8s `NetworkPolicy` at deployment, not app level.
- **Readiness 503 storm during rolling deploy** → Mitigation: k8s `readinessProbe` should use `failureThreshold: 3` and `periodSeconds: 10`; controller returns quickly (2-3s cap) so deploy does not stall.
- **DB check adds load under probe pressure** → Mitigation: `SELECT 1` is negligible; 10s probe interval × replicas is trivial. No connection pool exhaustion because we use the existing `Repo` pool.
- **S3 check flakiness causes false 503** → Mitigation: default to skipped for S3; only gate readiness on S3 when `HEALTH_CHECK_S3=true` or equivalent is set (documented, opt-in).
- **Caching by intermediate proxy returns stale 200** → Mitigation: `Cache-Control: no-store` and no ETag.

## Migration Plan

1. Add `TrebyWeb.HealthController` and router scope (no migration, no config change).
2. Deploy — existing probes (if any) can immediately switch to `/health` (liveness) and `/health/ready` (readiness). No rollback data concern; reverting is just removing routes.
3. Update k8s manifests / Helm chart / `docker-compose.yml` healthcheck (separate infra PR) to:
   ```yaml
   livenessProbe: { httpGet: { path: /health, port: 4000 }, initialDelaySeconds: 15, periodSeconds: 20 }
   readinessProbe: { httpGet: { path: /health/ready, port: 4000 }, initialDelaySeconds: 10, periodSeconds: 10, failureThreshold: 3 }
   ```
4. Rollback: remove routes/controller; probes fall back to TCP check if needed — no DB state to migrate.

## Open Questions

- Should `/health/ready` gate on S3 by default or only when S3 is configured? → Decision: gate only on DB by default; S3 is `skipped` unless explicitly enabled (env flag) — revisit if storage becomes hard requirement.
- Should we expose `version`/`commit SHA`/`uptime` in the JSON for debugging? → Deferred to follow-up; v1 keeps `{"status":"ok"}` minimal. Adding later is non-breaking.
- HEAD support? → `Plug.Head` in `Endpoint` already handles `HEAD /health` automatically; no extra work.
