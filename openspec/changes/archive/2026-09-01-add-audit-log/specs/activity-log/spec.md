## ADDED Requirements

### Requirement: Activity log as filtered presentation of audit trail
The system SHALL keep the candidate profile activity timeline as a user-facing, filtered presentation of hiring history, while the audit log is the immutable source of truth for compliance. The activity log behavior is unchanged except to document its relationship to the audit trail.

#### Scenario: Candidate profile timeline unchanged
- **WHEN** a user views a candidate profile
- **THEN** the 20 most recent activity events for that candidate are still shown in reverse chronological order with actor, action description, and relative timestamp

#### Scenario: Activity log remains separate from audit log storage
- **WHEN** an auditable action occurs
- **THEN** the system may write both an `activity_log` entry (for the candidate timeline) and an `audit_events` entry (for compliance) — the candidate timeline does not substitute for the audit trail and vice versa

#### Scenario: Audit trail is source of truth for investigations
- **WHEN** an admin needs to investigate "who changed what" beyond the candidate timeline (e.g., pipeline config, job publish, team changes)
- **THEN** the audit log at `/:company/app/settings/audit-log` is the authoritative source, not the candidate activity timeline
