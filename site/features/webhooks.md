# Webhooks

Send Treby events to external systems in real time through signed outbound webhooks. Connect Treby to automation tools (Zapier, Make), HRIS platforms, job boards, or your own services without writing code.

![Settings — Webhooks](/screenshots/41-settings-webhooks.png)

## What You Can Do

- Subscribe an external URL to the events you care about (a candidate is created, an application changes stage, an interview is scheduled, and more).
- Receive a structured JSON payload for every matching event, signed so you can verify it came from Treby.
- Test a subscription at any time, before saving it and afterwards, to confirm your endpoint is reachable and verifies the signature.

Only **admins** can configure webhooks. Members see nothing.

## Configuration

Admins open **Settings → Webhooks** and create a subscription:

- **Target URL** — an `https://` endpoint you control.
- **Events** — a comma-separated list of event patterns. Use:
  - An exact event, e.g. `candidate.created`
  - A namespace wildcard, e.g. `candidate.*` (all candidate events)
  - `*` for every event
- **Description** — optional label.
- **Secret** — optional. If you leave it blank, Treby generates one and shows it once. The secret is stored encrypted.
- **Active** — pause or resume a subscription without deleting it.

## Payload

Each delivery is a `POST` with a JSON body:

- `id` — unique delivery id (use it to deduplicate)
- `event` — the event name, e.g. `candidate.created`
- `entity_type` and `entity_id` — what changed
- `tenant_id` — your workspace id
- `occurred_at` — when it happened
- `actor` — who or what triggered it
- `data.current` — the full current record (omitted for deletions)
- `data.before` / `data.after` — the change, when available

### Verifying the Signature

Treby signs every request with HMAC-SHA256:

- Header `X-Treby-Signature` — `sha256=<hex>`
- Header `X-Treby-Event` — the event name
- Header `X-Treby-Delivery-Id` — the delivery id

Compute `HMAC-SHA256(secret, raw_body)` and compare it to the header value. This proves the request originated from Treby and was not tampered with.

## Delivery and Retries

- Failed deliveries are retried automatically with backoff.
- The **Logs** view on each subscription shows recent deliveries, their status, and the response, so you can see what was sent and debug failures.
- If your endpoint is temporarily down, Treby keeps retrying; no events are lost.

## Send Test

The **Send test** button is always available. It sends a synthetic `ping` event through the exact same signing and delivery path, so you can validate your URL and signature handling before going live — and re-check it any time after.
