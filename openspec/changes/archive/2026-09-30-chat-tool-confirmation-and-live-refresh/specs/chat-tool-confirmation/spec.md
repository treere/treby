## ADDED Requirements

### Requirement: Readable tool confirmation card

The system SHALL render each pending chat tool run as a human-readable summary card instead of a raw JSON dump. The card SHALL show an action title and key fields as label/value rows, plus a collapsed "Details" disclosure containing the full raw arguments for transparency.

#### Scenario: Confirmation shows summary rows

- **WHEN** the assistant needs confirmation for a destructive tool (e.g. creating a job)
- **THEN** the pending card shows the action title (e.g. "Create job") and key fields (e.g. title, location, employment type) as label/value rows, not only JSON

#### Scenario: Raw arguments still inspectable

- **WHEN** the user expands the "Details" disclosure on a confirmation card
- **THEN** the full raw tool arguments are shown as formatted text

#### Scenario: Long values stay contained

- **WHEN** a tool argument value exceeds ~120 characters
- **THEN** the summary row shows a truncated value while the full value remains visible in Details, and the card layout does not break

#### Scenario: Unknown tool still renders

- **WHEN** a pending run references a tool with no curated summary
- **THEN** the card renders via the generic fallback (humanized key labels, up to ~8 rows) without crashing

### Requirement: Curated summary for every destructive tool

The system SHALL provide a curated summary (`title` + `fields`) for every destructive tool, so each confirmation card shows meaningful field labels and selection. A generic fallback formatter SHALL remain only as a safety net for unknown or future tools.

#### Scenario: Every destructive tool has a curated summary

- **WHEN** the assistant needs confirmation for any destructive tool
- **THEN** the card uses that tool's curated title and field selection, never the generic fallback

#### Scenario: Fallback only for unknown tools

- **WHEN** a pending run references a tool with no curated summary (unknown or newly added)
- **THEN** the card shows humanized argument keys (e.g. `pipeline_id` → "Pipeline") with truncated values without crashing

### Requirement: Confirm and cancel behavior unchanged

The system SHALL keep the existing Confirm/Cancel semantics: Confirm executes the tool with the socket's tenant and user and logs an audit event; Cancel marks the run rejected with no mutation.

#### Scenario: Confirm executes

- **WHEN** the user clicks Confirm on a summary card
- **THEN** the tool executes, an audit event is logged, and the chat reloads

#### Scenario: Cancel does nothing

- **WHEN** the user clicks Cancel on a summary card
- **THEN** the run is marked rejected and no mutation occurs
