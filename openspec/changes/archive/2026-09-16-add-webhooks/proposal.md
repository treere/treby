## Why

Treby captures every state-changing action in an immutable, tenant-isolated audit trail (`audit_events`). That trail is currently only consumed by the admin audit-log UI. External systems (Zapier/Make automations, HRIS, job boards, custom portals, internal tooling) cannot react to Treby events programmatically. Administrators need a way to subscribe external HTTP endpoints to domain events so Treby can push a structured payload whenever something happens (candidate created, application stage moved, interview scheduled, etc.).

This change introduces **outbound webhooks**: admin-configurable HTTP subscriptions that fan out from the existing audit log to third-party endpoints, with wildcard event matching, signed payloads, encrypted secrets, durable retry, and an always-available test sender.

## What Changes

- Add a `webhook_subscriptions` table: `tenant_id`, `target_url`, `events` (text array of patterns), `secret` (encrypted at rest via `Treby.Encrypted.Binary`), `active` (bool), `description`.
- Add a `webhook_delivery_logs` table: `tenant_id`, `subscription_id`, `action`, `payload` (JSONB), `status`, `attempts`, `last_response`, `inserted_at` — for admin visibility and replay.
- Add a `Treby.Webhooks` context with: `create_subscription/2`, `update_subscription/2`, `list_subscriptions/1`, `delete_subscription/2`, `dispatch/1` (event fan-out), and entity registry for full-payload serialization.
- Hook `Treby.Webhooks.dispatch/1` into `Treby.Audit.log_event/4` and `log_event_multi/4` so every audit event becomes a potential webhook trigger through the single existing choke point — no changes to the ~30 call sites.
- Add `Treby.Workers.WebhookDelivery` (Oban worker, `max_attempts: 5`, exponential backoff): loads the audit event, (re)matches active subscriptions, fetches the full entity via an entity-type registry, sanitizes it (reusing `Treby.Audit.sanitize_metadata/2` to drop secrets/PII), builds a signed JSON envelope, and POSTs it with `Req`.
- Add an admin-only **Webhooks** settings page (`Settings.WebhooksLive`) under the existing `:admin` live session: list subscriptions, create/edit (URL, event patterns incl. wildcard, active toggle, description), a permanently-enabled **Send test** action (validates URL + signature before saving and anytime after), and a delivery-log view with status/response and replay.
- Add router route `/:tenant_slug/app/settings/webhooks` and nav entry, gated by `Hooks.RequireRole %{role: "admin"}`.

## Capabilities

### New Capabilities
- `webhooks`: outbound, admin-configured HTTP webhook subscriptions that fan out from audit events, with wildcard event matching, encrypted secrets, signed payloads, durable Oban-based retry, a delivery log, and an always-available test sender.

### Modified Capabilities
- `audit-log`: the audit log becomes the single source of truth that also drives outbound webhooks; `Treby.Audit.log_event`/`log_event_multi` gain a non-blocking dispatch hook. No schema change to `audit_events`.
- `role-based-access`: webhook configuration and the delivery log are admin-only (members cannot view or configure).
- `multi-tenancy`: webhook subscriptions and delivery logs are strictly tenant-scoped; one tenant's subscriptions never fire for or deliver to another tenant.

## Impact

- Dependencies: no new external deps. Uses existing `Oban`, `Req`, `Cloak` (`Treby.Vault`/`Treby.Encrypted.Binary`), `Phoenix.LiveView`, `PostgreSQL` JSONB.
- Code: new `lib/treby/webhooks/*` (context + entity registry + schema), `lib/treby/workers/webhook_delivery.ex`, new `lib/treby_web/live/settings_live/webhooks.ex` (+ components), edits to `lib/treby/audit.ex` (dispatch hook), `lib/treby_web/router.ex`, `lib/treby_web/components/layouts.ex` nav.
- Migrations: `priv/repo/migrations/*_create_webhook_subscriptions.exs`, `*_create_webhook_delivery_logs.exs` (indexes on `tenant_id`, `subscription_id`, `action`, `inserted_at`).
- Build/deploy: one new env key already covered by `CLOAK_KEY` (reused for secret encryption). No new services.
- Docs: add `site/features/webhooks.md` user-manual page (admin feature) and a short mention in `site/architecture.md`; both English-only per AGENTS.md, no code references.
