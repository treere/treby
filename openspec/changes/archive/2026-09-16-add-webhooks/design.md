## Context

Treby already emits a complete, namespaced, tenant-isolated audit trail through `Treby.Audit.log_event/4` and `log_event_multi/4`. The action vocabulary is stable and namespaced (`<resource>.<verb>`), e.g. `candidate.created`, `application.stage_moved`, `interview.scheduled`, `pipeline.stage_deleted`, `job.updated`, `tenant.updated` — ~35 actions across ~12 namespaces. `AuditEvent` already stores `entity_type`, `entity_id`, `metadata` (before/after), `actor`, `tenant_id`, and request context.

External integration today is only **outbound to Google Calendar** (OAuth + free/busy + event create/delete). There is no generic, user-configurable outbound mechanism and no inbound API. Oban is already configured and used for durable, retrying delivery (`Treby.Workers.SendScheduledMessage`). Secrets at rest are already encrypted via `Treby.Vault` (Cloak) and the `Treby.Encrypted.Binary` Ecto type.

Stakeholders: workspace admins (configure integrations), external automation/platform engineers (consume events). The feature must be admin-only, tenant-isolated, fail-safe (a bad webhook must never break the primary mutation), and low-overhead on the request path.

## Goals / Non-Goals

**Goals:**
- Admin-configurable outbound webhook subscriptions, tenant-scoped, with wildcard event matching (`candidate.*`, `*`).
- Fan-out from the existing audit log through a single dispatch hook — no new instrumentation at call sites.
- Full (shallow) entity payload, PII/secret-safe via reuse of `Treby.Audit.sanitize_metadata/2`.
- Signed payloads (HMAC-SHA256), encrypted secrets at rest, SSL-verified delivery (Req default).
- Durable retry (Oban, `max_attempts: 5`, exponential backoff) plus an admin-visible delivery log and replay.
- Always-available **Send test** (pre-save validation and anytime after).

**Non-Goals:**
- Inbound webhooks / a public read/write API (deferred; this change is outbound only).
- Pre-built connectors for specific vendors (Zapier app, HRIS sync) — the generic webhook is the integration surface; specific connectors can be layered later.
- Nested/relational payload expansion beyond the top-level entity row.
- Per-event throttling of the producing action; only delivery-side rate limiting.

## Decisions

**D1: Fan-out from the audit log, not new call sites**
- Chosen: add `Treby.Webhooks.dispatch/1` invoked from `Treby.Audit.log_event/4` (after insert) and `log_event_multi/4` (as an extra `Ecto.Multi` step so it commits with the same transaction). The audit event is the single source of truth for "what happened".
- Rationale: avoids touching ~30 contexts, guarantees coverage regardless of entry point (UI, bulk, CSV, portal, AI), and keeps webhook logic in one place.
- Alternative: emit events from each context — rejected (duplication, drift risk).

**D2: Matching semantics**
- A subscription's `events` is a text array of patterns. Match rule for an incoming `action`:
  - exact equality (`application.created`), OR
  - pattern `"*"` matches everything, OR
  - pattern `"<ns>.*"` (e.g. `candidate.*`) matches any `action` whose namespace equals `<ns>` (i.e. `String.starts_with?(action, "<ns>.")`).
- Rationale: cheap, predictable, covers both "specific event" and "whole namespace" without regex.

**D3: Tenant-scoped dispatch gate**
- `dispatch/1` first checks whether the event's tenant has ≥1 active subscription; if none, it returns immediately without enqueuing anything. This keeps the request path free of Oban work when no webhooks are configured.
- When subscriptions exist, enqueue one `WebhookDelivery` job carrying the `audit_event_id`. Matching is re-evaluated inside the worker (subscriptions may change after enqueue).

**D4: Full payload, fetched in the worker**
- The worker loads the `AuditEvent`, then fetches the full current entity via an entity-type → schema registry (`Treby.Webhooks.Entities.fetch(entity_type, entity_id)`). For delete events the entity no longer exists, so `data.current` is `null` and `data.before` (from audit `metadata`) is used.
- Payload is the **shallow** sanitized entity struct only — no nested associations. Unknown `entity_type` degrades gracefully: send `metadata` only + log a warning (never crash).
- Sanitization reuses `Treby.Audit.sanitize_metadata/2` (drops `password`/`token`/`otp`/`resume_content` and truncates long strings).

**D5: Envelope & signing**
- JSON envelope:
  ```json
  {
    "id": "<delivery-uuid>",
    "event": "candidate.created",
    "entity_type": "candidate",
    "entity_id": "uuid",
    "tenant_id": "uuid",
    "occurred_at": "ISO8601",
    "actor": { "type": "user", "id": "uuid" },
    "data": { "current": { ... }, "before": { ... }, "after": { ... } }
  }
  ```
- Headers: `X-Treby-Signature: sha256=<hmac>` (HMAC-SHA256 over raw request body keyed by the subscription secret), `X-Treby-Event`, `X-Treby-Delivery-Id`. `tenant_id` is the UUID (stable, rename-safe) per decision; `slug` is intentionally omitted to keep the contract stable.
- Delivery via `Req.post/3`; TLS verification left at Req default (on). Failed deliveries surface in the delivery log and are retried by Oban.

**D6: Secret storage (encrypted at rest)**
- The subscription `secret` column uses `Treby.Encrypted.Binary` (Cloak/AES-GCM via `Treby.Vault`), consistent with other encrypted fields in the app. The plaintext secret is shown once at creation (and via "reveal"/regenerate) and used only to compute the HMAC at delivery time.

**D7: Retry & rate limiting**
- `Treby.Workers.WebhookDelivery` uses `use Oban.Worker, queue: :webhooks, max_attempts: 5` with exponential backoff (mirrors `SendScheduledMessage`). Each attempt records status/response in `webhook_delivery_logs`.
- Rate limiting: a per-tenant concurrency cap on the `:webhooks` Oban queue (queue-level `limit`/`limit_document`) plus optional global cap, so a tenant subscribed to `*` during a bulk import cannot starve other tenants. Default to a modest per-tenant concurrency (e.g. 5) — tune via config.

**D8: Always-available Send test**
- The admin Webhooks UI exposes **Send test** on both the edit form (before save, using the in-form URL + a generated ephemeral secret) and on every saved subscription row. It fires a synthetic `ping` event through the same envelope/signing/delivery path so the user can validate URL reachability and signature verification whenever they want. `ping` is never matched by real subscriptions (only the test path uses it).

**D9: Authorization & multi-tenancy**
- Webhook config + delivery log live under the existing `:admin` live session (`Hooks.RequireRole %{role: "admin"}`); members are redirected. All context reads/writes require `tenant_id`; queries filter by `tenant_id`. Candidate portal and public pages never touch webhooks.

## Risks / Trade-offs

- **Webhook failure must not break the primary action** → dispatch is fire-and-forget via Oban; audit insert and business mutation are unaffected by downstream delivery failures.
- **Write amplification / noise** → dispatch short-circuits when no active subscriptions exist for the tenant; only matching subscriptions enqueue a job.
- **PII egress** → full entity payloads may contain candidate PII. Mitigation: reuse `sanitize_metadata/2`; document that admins control which events fire; never include raw resume content or auth secrets.
- **Secret leakage** → secret encrypts at rest; shown once. Mitigation: same Cloak path as other secrets; admin-only.
- **Bulk-import storm** → a `*` subscription during CSV import could enqueue thousands of jobs. Mitigation: queue concurrency cap (D7) + Oban backoff; consider batching later.
- **Entity registry drift** → new entity types added without registry entry degrade to metadata-only payload. Mitigation: `Tasks` checklist + dev warning; payload never crashes.

## Migration Plan

1. `mix ecto.gen.migration create_webhook_subscriptions` and `create_webhook_delivery_logs`; add tables + indexes (`tenant_id`, `subscription_id`, `action`, `inserted_at`).
2. Implement `Treby.Webhooks` context, entity registry, `WebhookDelivery` worker; wire `dispatch/1` into `Treby.Audit`.
3. Add admin `Settings.WebhooksLive` route + nav (admin-gated); add Send test + delivery log UI.
4. Deploy `mix ecto.migrate`; no backfill (webhooks only fire for events after deploy).
5. Rollback: `mix ecto.rollback`; business tables unaffected; only webhook rows lost.

## Open Questions

- Should `data` expose a stable `schema_version` field so consumers can evolve? (Recommend v1 string in envelope; defer.)
- Should delivery failures notify the admin (email/notification) after N attempts? (Defer; log-only for v1.)
- Should we support a per-subscription custom `X-*` header or basic auth? (Defer; signature covers authenticity for v1.)
