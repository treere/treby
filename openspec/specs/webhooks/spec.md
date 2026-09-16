# Webhooks

## Purpose

Allow workspace administrators to subscribe external HTTP endpoints to Treby domain events, so third-party systems (automations, HRIS, job boards, custom portals) can react to hiring activity (candidate created, application stage moved, interview scheduled, etc.) with a signed, full-payload JSON delivery. Webhooks fan out from the existing immutable audit log.

## Requirements

### Requirement: Admin-only webhook subscription management
The system SHALL allow only `admin`-role members to create, edit, activate, deactivate, and delete webhook subscriptions, and to view the delivery log. Members SHALL be denied all webhook configuration and log access.

#### Scenario: Admin configures a webhook
- **WHEN** an admin opens Settings → Webhooks
- **THEN** they can create a subscription with a target URL, an event-pattern list (including wildcards), an optional description, and an active toggle

#### Scenario: Member is denied webhook access
- **WHEN** a member navigates to the webhooks route or calls the context directly
- **THEN** they are redirected to the dashboard with a permission-denied flash and no subscription data is returned

#### Scenario: Secret is encrypted at rest
- **WHEN** a subscription secret is stored
- **THEN** it is encrypted via `Treby.Encrypted.Binary` (Cloak/AES-GCM) and is never persisted in plaintext

### Requirement: Wildcard event matching
The system SHALL match an audit `action` against a subscription's `events` patterns using exact match, namespace wildcard (`<ns>.*`), and global wildcard (`*`).

#### Scenario: Exact event match
- **WHEN** a subscription's `events` contains `candidate.created` and a `candidate.created` audit event occurs
- **THEN** the subscription is selected for delivery

#### Scenario: Namespace wildcard match
- **WHEN** a subscription's `events` contains `candidate.*` and a `candidate.updated` (or `candidate.deleted`, `candidate.merged`) audit event occurs
- **THEN** the subscription is selected for delivery

#### Scenario: Global wildcard match
- **WHEN** a subscription's `events` contains `*` and any audit event occurs for that tenant
- **THEN** the subscription is selected for delivery

#### Scenario: No match
- **WHEN** no pattern in a subscription matches the action
- **THEN** that subscription is not selected for delivery

### Requirement: Fan-out from the audit log
The system SHALL dispatch webhook deliveries from the existing `Treby.Audit.log_event/4` and `log_event_multi/4` choke points without modifying individual emitting contexts.

#### Scenario: Event with no subscriptions is a no-op
- **WHEN** an audit event is recorded for a tenant with no active subscriptions
- **THEN** no Oban job is enqueued and the request path is unaffected

#### Scenario: Event with matching subscriptions enqueues delivery
- **WHEN** an audit event matches at least one active subscription for the tenant
- **THEN** a `WebhookDelivery` job is enqueued carrying the audit event id, and delivery happens after the producing transaction commits

#### Scenario: Delivery failure does not affect primary action
- **WHEN** a downstream webhook endpoint is unreachable or errors
- **THEN** the original business mutation and audit insert remain committed and unaffected

### Requirement: Signed full-payload delivery
The system SHALL deliver a JSON envelope containing the full (shallow) current entity, the audit before/after metadata, tenant id (UUID), actor, and occurrence time, signed with HMAC-SHA256 keyed by the subscription secret.

#### Scenario: Successful delivery
- **WHEN** a `WebhookDelivery` worker runs for a matched subscription
- **THEN** it POSTs the JSON envelope to `target_url` with headers `X-Treby-Signature` (sha256 HMAC), `X-Treby-Event`, and `X-Treby-Delivery-Id`, over TLS-verified HTTPS

#### Scenario: Deleted entity payload
- **WHEN** the event is a delete and the entity no longer exists
- **THEN** `data.current` is `null` and `data.before` carries the pre-delete snapshot from audit metadata

#### Scenario: Unknown entity type degrades gracefully
- **WHEN** the audit `entity_type` is not in the entity registry
- **THEN** the system delivers `metadata` only and logs a warning, without raising

#### Scenario: PII and secrets are redacted
- **WHEN** any payload is built
- **THEN** fields such as `password`, `token`, `otp`, and `resume_content` are dropped and long strings truncated, reusing `Treby.Audit.sanitize_metadata/2`

### Requirement: Durable retry and delivery log
The system SHALL retry failed deliveries via Oban (`max_attempts: 5`, exponential backoff) and record every delivery attempt in a tenant-scoped delivery log with status and response.

#### Scenario: Failed delivery is retried
- **WHEN** a POST returns a non-2xx status or raises
- **THEN** Oban retries up to 5 attempts with exponential backoff and each attempt is logged

#### Scenario: Delivery log is visible to admins
- **WHEN** an admin views a subscription's delivery log
- **THEN** they see attempts, status, HTTP response, and timestamp, scoped to the current tenant

#### Scenario: Rate limiting protects the system
- **WHEN** many deliveries are enqueued (e.g. bulk import with a `*` subscription)
- **THEN** the `:webhooks` Oban queue applies a per-tenant concurrency cap so other tenants are not starved

### Requirement: Always-available test sender
The system SHALL let an admin send a synthetic `ping` test through the same envelope, signing, and delivery path at any time — both before saving a new subscription (using the in-form URL and an ephemeral secret) and on any saved subscription.

#### Scenario: Test before save
- **WHEN** an admin enters a URL and secret in the new-subscription form and clicks Send test
- **THEN** a `ping` event is delivered to that URL signed with the entered secret, without persisting the subscription

#### Scenario: Test on saved subscription
- **WHEN** an admin clicks Send test on an existing subscription row
- **THEN** a `ping` event is delivered to its URL signed with its stored secret
