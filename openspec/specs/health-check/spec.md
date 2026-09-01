# Health Check

## Purpose

Unauthenticated HTTP health and readiness probes for infrastructure monitoring (Kubernetes liveness/readiness, load balancers, Docker HEALTHCHECK). Provides fast, tenant-agnostic endpoints that indicate when the application is running and when it is ready to serve traffic based on downstream dependency checks.

## Requirements
### Requirement: Liveness health endpoint
The system SHALL expose unauthenticated liveness endpoints at `GET /health` and `GET /healthz` that return `200 OK` with a JSON body when the application process is running, without requiring authentication, session, or tenant context.

#### Scenario: Liveness probe succeeds when app is running
- **WHEN** any client (unauthenticated) sends `GET /health`
- **THEN** the system responds with HTTP `200` and `content-type: application/json`
- **AND** the JSON body contains `{"status":"ok"}`
- **AND** the response includes `cache-control: no-store` (or `no-store, no-cache, must-revalidate`)
- **AND** no authentication redirect, CSRF check, or `tenant_slug` is required

#### Scenario: Alias healthz behaves identically
- **WHEN** a client sends `GET /healthz`
- **THEN** the system responds identically to `GET /health` with `200` and `{"status":"ok"}`

#### Scenario: HEAD is supported
- **WHEN** a client sends `HEAD /health`
- **THEN** the system responds with `200` and the same headers as `GET` but with an empty body (via `Plug.Head`)

#### Scenario: Liveness does not depend on downstream services
- **WHEN** the database or object storage is unavailable but the BEAM is serving HTTP
- **THEN** `GET /health` still returns `200` with `{"status":"ok"}` (downstream is not checked)

### Requirement: Readiness health endpoint
The system SHALL expose an unauthenticated readiness endpoint at `GET /health/ready` that checks connectivity to critical dependencies (PostgreSQL) and returns `200` when ready or `503` when not ready, with a JSON body describing each check.

#### Scenario: Readiness succeeds when database is reachable
- **WHEN** a client sends `GET /health/ready` and PostgreSQL is reachable
- **THEN** the system responds with HTTP `200` and JSON `{"status":"ok","checks":{"database":"ok"}}` (S3 may be `"ok"` or `"skipped"` — see below)
- **AND** the check completes within 3 seconds

#### Scenario: Readiness fails when database is unreachable
- **WHEN** a client sends `GET /health/ready` and the PostgreSQL check fails or times out (>2s)
- **THEN** the system responds with HTTP `503` and JSON `{"status":"error","checks":{"database":"error", ...}}` (no raw exception or PII leaked)

#### Scenario: Readiness does not require tenant context
- **WHEN** a client sends `GET /health/ready` without any session or `tenant_slug`
- **THEN** the system performs the check without tenant scoping and returns `200` or `503` as above

#### Scenario: S3 check is best-effort and skipped by default
- **WHEN** a client sends `GET /health/ready` and object storage is not configured or S3 gating is not enabled
- **THEN** the `checks` object contains `"storage":"skipped"` (or omits storage) and does not cause a `503` — readiness is determined solely by the database check
- **AND** when S3 gating is explicitly enabled and S3 is unreachable, readiness MAY return `503` with `"storage":"error"`

### Requirement: Public unauthenticated access and observability
The health endpoints SHALL be publicly accessible (no `RequireAuth`, `RequireMembership`, or `RequireRole`), tenant-agnostic, and observable via existing request telemetry without exposing sensitive data.

#### Scenario: No authentication required
- **WHEN** an unauthenticated request is sent to any `/health*` endpoint
- **THEN** the system does not redirect to `/login` or return `401`/`403`, and does not require a `current_scope`

#### Scenario: No sensitive data exposed
- **WHEN** any health endpoint responds (200 or 503)
- **THEN** the body contains only `status`, `checks` (for readiness), and optionally non-sensitive metadata — never tenant data, user data, stack traces, or raw exception messages

#### Scenario: Requests are traced
- **WHEN** a health probe is received
- **THEN** it carries a `request-id` (via `Plug.RequestId`) and emits `[:phoenix, :endpoint, :stop]` telemetry like any other request, so probes appear in logs/metrics

#### Scenario: No caching
- **WHEN** any health endpoint responds
- **THEN** the response includes `cache-control: no-store, no-cache, must-revalidate` (or equivalent `no-store`) and `pragma: no-cache` to prevent caching by proxies or CDNs

#### Scenario: Excluded from HTTPS redirect
- **WHEN** a client sends an HTTP request to any `/health*` endpoint in production where `force_ssl` with `rewrite_on: [:x_forwarded_proto]` is enabled
- **THEN** the system does NOT redirect to HTTPS (no 301/302) and serves the health response directly, because `/health`, `/healthz`, and `/health/ready` are excluded via `force_ssl.exclude.paths`

