## 1. Schema & migrations
- [x] `mix ecto.gen.migration create_webhook_subscriptions` — table `webhook_subscriptions` (`tenant_id` FK, `target_url`, `events text[]`, `secret` via `Treby.Encrypted.Binary`, `active` bool default true, `description`). Index `(tenant_id)`.
- [x] `mix ecto.gen.migration create_webhook_delivery_logs` — table `webhook_delivery_logs` (`tenant_id` FK, `subscription_id` FK, `action`, `payload` jsonb, `status`, `attempts`, `last_response`, `inserted_at`). Indexes `(tenant_id)`, `(subscription_id)`, `(action)`, `(inserted_at)`.

## 2. Webhook context & entity registry
- [x] `lib/treby/webhooks/webhook_subscription.ex` schema + changeset (validate `target_url` is https, `events` non-empty when active).
- [x] `lib/treby/webhooks/webhook_delivery_log.ex` schema.
- [x] `lib/treby/webhooks/entities.ex` — registry `entity_type -> schema module` for the ~12 namespaces; `fetch/2` returns sanitized shallow struct or `nil`; unknown type returns `{:unknown, metadata}`.
- [x] `lib/treby/webhooks/webhooks.ex` context: `list_subscriptions/1`, `get_subscription/2`, `create_subscription/2`, `update_subscription/2`, `delete_subscription/2`, `active_for_tenant?/1`, `matching_subscriptions/2` (wildcard match), `dispatch/1` (gate + enqueue), `build_envelope/2`, `sign/2` (HMAC-SHA256), `log_delivery/1`.
- [x] Reuse `Treby.Audit.sanitize_metadata/2` in envelope building; never add nested associations.

## 3. Audit hook
- [x] In `lib/treby/audit.ex`: call `Treby.Webhooks.dispatch(event)` after `Repo.insert` in `log_event/4`.
- [x] Add `Treby.Webhooks.dispatch_multi(multi, name, event_fn)` step for `log_event_multi/4` so dispatch commits with the same transaction.

## 4. Oban worker
- [x] `lib/treby/workers/webhook_delivery.ex` — `use Oban.Worker, queue: :webhooks, max_attempts: 5`; load audit event, re-match active subscriptions, fetch entity, build + sign envelope, `Req.post/3` with `X-Treby-*` headers, record `webhook_delivery_logs`, raise on failure for Oban retry.
- [x] Configure `:webhooks` queue with per-tenant concurrency cap in `config`/Oban init.

## 5. Admin UI
- [x] `lib/treby_web/live/settings_live/webhooks.ex` (+ index/show/form components) under `:admin` live session: list, create/edit (URL, events multi-select with wildcard options, active, description), delete with confirm.
- [x] **Send test** on new form (ephemeral secret) and on each saved row — fires synthetic `ping` through the delivery path.
- [x] Delivery-log view per subscription (status, attempts, response, timestamp) with replay action.
- [x] Route `/:tenant_slug/app/settings/webhooks` in `router.ex` + nav entry in `layouts.ex`, gated by `Hooks.RequireRole %{role: "admin"}`.

## 6. Tests
- [x] Context tests: wildcard matching (exact/`ns.*`/`*`), tenant isolation, `dispatch` no-op without subscriptions, encrypted secret round-trip, envelope shape + HMAC verification, deleted-entity `current: null`, unknown entity_type degradation, PII redaction reuse.
- [x] Worker test: success delivery, retry on failure (mock endpoint), delivery-log write.
- [x] Live test: admin can manage, member denied, send-test validates URL+signature.

## 7. Docs
- [x] `site/features/webhooks.md` (English-only user manual: where to find, how to configure, event list, wildcard examples, Send test, delivery log).
- [x] Short mention in `site/architecture.md`.
- [x] Regenerate screenshots via `node scripts/screenshots.mjs` for the new settings page (light + dark).
