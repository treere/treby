# Audit Log — AI delta

## ADDED Requirements

### Requirement: AI-initiated audit events

The system SHALL log every AI-executed mutation as an audit event with `actor_type: "system"` (or `user` with `via: "ai"`), `actor_id: user.id`, `tenant_id`, `action`, `entity_type`, `entity_id`, and `metadata: %{via: "ai", prompt_excerpt, tool, args}`. Confirmation-gated actions SHALL only be logged when actually executed, not when pending.

#### Scenario: AI write logged
- **WHEN** the user confirms an AI-proposed `delete_job` tool
- **THEN** an `audit_events` row is inserted with `actor_id` equal to the confirming user and `metadata.via == "ai"`

#### Scenario: Pending not logged
- **WHEN** the assistant proposes a destructive tool but the user has not confirmed
- **THEN** no audit event is created

#### Scenario: Read not logged as audit
- **WHEN** the assistant performs a read-only tool
- **THEN** no `audit_events` row is required (reads are not auditable mutations)
