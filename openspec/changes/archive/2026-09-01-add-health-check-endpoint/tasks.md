## 1. Backend — Health controller and routes

- [x] 1.1 Create `TrebyWeb.HealthController` with `health/2` (liveness) and `ready/2` (readiness) actions returning JSON `{"status":"ok"}` / `{"status":"error",...}` and `cache-control: no-store` headers
- [x] 1.2 Add unauthenticated router scope in `TrebyWeb.Router` for `GET /health`, `GET /healthz` (alias to same action), and `GET /health/ready` with `pipe_through []` (no browser/session/auth plugs)
- [x] 1.3 Implement DB readiness check via `Treby.Repo.query("SELECT 1")` with 2s timeout, parallel aggregation with `Task` (overall 3s budget), fail-closed for DB → `503` on error/timeout and `200` on success, with sanitized error body
- [x] 1.4 Implement storage check as best-effort skipped-by-default (no `503` when S3 not configured; only gate when explicitly enabled), include `"storage":"skipped"` in `checks` when skipped
- [x] 1.5 Ensure JSON `content-type: application/json`, `pragma: no-cache`, and `Plug.Head` handles `HEAD /health` via existing `Plug.Head` in `TrebyWeb.Endpoint`

## 2. Tests

- [x] 2.1 Add `test/treby_web/controllers/health_controller_test.exs` covering `GET /health` (200 + json + no-store + no auth), `GET /healthz` alias, `HEAD /health`, and unauthenticated access
- [x] 2.2 Add readiness tests for `GET /health/ready` success (200 when DB up) and failure (503 when DB down — mock/stub `Repo.query` or simulate timeout), and `skipped` storage case
- [x] 2.3 Verify probes are tenant-agnostic: requests without `tenant_slug` or session still succeed

## 3. Specs, docs and validation

- [x] 3.1 Update canonical spec at `openspec/specs/health-check/spec.md` with Purpose/Requirements and Scenario WHEN/THEN (create if not exists — this is a new capability)
- [x] 3.2 Update infra docs/comments if needed (Docker `HEALTHCHECK` / k8s manifest example) — no `site/` user manual page required for this infra-only endpoint (if adding, update `site/features/index.md` and `site/.vitepress/config.ts` sidebar)
- [x] 3.3 Run `mix precommit` and `openspec validate --strict` and fix all issues (format, credo, sobelow, compile warnings, tests)
