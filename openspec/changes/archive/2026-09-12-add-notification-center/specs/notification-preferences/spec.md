## ADDED Requirements

### Requirement: Per-type email and inbox toggles
The system SHALL allow tenant admins to configure each notification type with independent `email` and `inbox` booleans, stored as `tenant.settings["notifications"][type] = {"email": bool, "inbox": bool}`. Legacy boolean values SHALL be read as `{"email": bool, "inbox": true}` for backward compatibility.

#### Scenario: New shape with two toggles per type
- **WHEN** an admin opens Settings → Notifications
- **THEN** each notification type shows two toggles: "Email" and "In-app"
- **AND** toggling either persists immediately and affects only that channel

#### Scenario: Legacy boolean is migrated on read
- **WHEN** a tenant still has `tenant.settings["notifications"]["new_application_team"] = true` (boolean)
- **THEN** the system treats it as `{"email": true, "inbox": true}`
- **AND** the next write persists the object shape

#### Scenario: Inbox respects preference
- **WHEN** a hiring event occurs and `inbox` is false for that type
- **THEN** no inbox row is created for that event (email may still be sent if `email` is true)

#### Scenario: Email respects preference
- **WHEN** a hiring event occurs and `email` is false for that type
- **THEN** no email is sent for that event (inbox row may still be created if `inbox` is true)

### Requirement: Tenant-level retention setting
The system SHALL allow tenant admins to configure how long read notifications are retained, via `tenant.settings["notifications_retention_days"]` with allowed values 7, 14, 30, 60, 90 (default 30).

#### Scenario: Default retention
- **WHEN** a tenant has no `notifications_retention_days` set
- **THEN** the effective retention is 30 days

#### Scenario: Admin changes retention
- **WHEN** an admin selects a new retention value in Settings → Notifications and saves
- **THEN** the value is persisted and the next pruner run uses the new threshold

#### Scenario: Invalid retention is rejected
- **WHEN** an admin submits a value outside 7/14/30/60/90
- **THEN** the system rejects the change with a validation error and the previous value is kept
