# Bulk Operations

## Delta

## MODIFIED Requirements

### Requirement: Bulk move to stage
The system SHALL allow moving multiple selected applications to a specific pipeline stage. The bulk action bar controls SHALL be rendered inside a form so change/submit events reach the server without client-side errors.

#### Scenario: Bulk move via action bar
- **WHEN** a user selects applications and clicks "Move to Stage"
- **THEN** a dropdown shows available stages in the pipeline
- **AND** selecting a stage and confirming moves all selected applications

#### Scenario: Bulk move controls inside a form
- **WHEN** a user selects candidates on the pipeline board and opens the bulk action bar
- **THEN** the stage selector and move button are rendered inside a form element with `phx-change` / `phx-submit` wiring
- **AND** no "form events require the input to be inside a form" error is raised in the browser console

#### Scenario: Bulk move with message templates
- **WHEN** the target stage has a message template configured
- **THEN** a confirmation dialog shows "Send message to all X candidates?" with Send/Skip options

#### Scenario: Bulk move in single transaction
- **WHEN** a bulk move is executed
- **THEN** all moves happen in a single database transaction
- **AND** if any move fails, all moves are rolled back