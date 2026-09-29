# Chat Tool Confirmation

## Purpose

Render assistant tool confirmations as human-readable summary cards instead of raw JSON, with a curated summary for every destructive tool.

## Requirements

### Requirement: Readable tool confirmation card
The system SHALL render each pending tool run as a summary card with the action title, key fields as label/value rows, and a collapsed Details section with the full raw arguments. Long values SHALL be truncated in the rows with the full value kept in Details.

#### Scenario: Confirmation shows summary rows
- **WHEN** the assistant needs confirmation for a destructive tool
- **THEN** the card shows the action title and key fields as label/value rows, not only raw data

#### Scenario: Raw arguments still inspectable
- **WHEN** the user expands Details on a confirmation card
- **THEN** the full raw tool arguments are shown

### Requirement: Curated summary for every destructive tool
The system SHALL provide a curated summary (title + fields) for every destructive tool. A generic fallback formatter SHALL remain only as a safety net for unknown or future tools.

#### Scenario: Every destructive tool has a curated summary
- **WHEN** the assistant needs confirmation for any destructive tool
- **THEN** the card uses that tool's curated title and field selection, never the generic fallback

#### Scenario: Fallback only for unknown tools
- **WHEN** a pending run references a tool with no curated summary
- **THEN** the card shows humanized argument keys with truncated values without crashing

### Requirement: Confirm and cancel behavior unchanged
The system SHALL keep existing Confirm/Cancel semantics: Confirm executes the tool and logs an audit event; Cancel marks the run rejected with no mutation.

#### Scenario: Confirm executes
- **WHEN** the user clicks Confirm on a summary card
- **THEN** the tool executes, an audit event is logged, and the chat reloads

#### Scenario: Cancel does nothing
- **WHEN** the user clicks Cancel on a summary card
- **THEN** the run is marked rejected and no mutation occurs
