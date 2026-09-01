## Why

Treby currently exposes no unauthenticated HTTP endpoint suitable for Kubernetes liveness and readiness probes. Without it, deployments on k8s cannot reliably detect when the application is running, when it is ready to serve traffic, or when dependent services (database, object storage) are unavailable, leading to manual checks and degraded rollout/restart behaviour.

## What Changes

- Add public, unauthenticated `GET /health` (and alias `GET /healthz`) endpoint returning `200 OK` with a small JSON payload when the application is running. No authentication or tenant context required.
- Add optional deeper readiness check `GET /health/ready` (or `?ready=true` variant — decided in design) that verifies connectivity to critical dependencies (PostgreSQL via `Ecto`, and S3/RustFS if configured) and returns `200` when ready / `503` when not ready, with a JSON body describing each check.
- Endpoint must be lightweight, not go through browser pipeline (no session, CSRF, locale), and must respond quickly (< 100ms when healthy).
- No UI changes; the endpoint is for infrastructure monitoring only.

## Capabilities

### New Capabilities
- `health-check`: Unauthenticated HTTP health and readiness probes for infrastructure monitoring (k8s liveness/readiness, load balancers). Covers routes, response format, status codes, dependency checks, and observability requirements.

### Modified Capabilities
- None — no existing spec requirements are changed.

## Impact

- **Code**: New controller/plug under `lib/treby_web` (e.g. `TrebyWeb.HealthController` or `TrebyWeb.Plugs.HealthCheck`) and route entries in `TrebyWeb.Router` and/or `TrebyWeb.Endpoint` for earliest response.
- **APIs**: New public GET endpoints: `/health`, `/healthz`, and `/health/ready` (final path set in design). Unauthenticated and tenant-agnostic; must be excluded from auth/membership plugs.
- **Dependencies**: None new — uses existing `Ecto` and `ExAWS`/`Req` checks; no new hex packages.
- **Systems / Ops**: Enables `livenessProbe` and `readinessProbe` configuration in Kubernetes manifests, Helm charts, and Docker `HEALTHCHECK`. No DB migrations.
