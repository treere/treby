# Bulk Operations

## Purpose

Eliminate repetitive one-at-a-time actions by allowing hiring managers to act on multiple candidates or applications simultaneously.

## Requirements

### Requirement: Select multiple items
The system SHALL allow selecting multiple candidates or applications via checkboxes.

#### Scenario: Checkbox on candidate list
- **WHEN** a user views the candidates list
- **THEN** each row has a checkbox for selection

#### Scenario: Checkbox on pipeline board
- **WHEN** a user views the pipeline Kanban board
- **THEN** each candidate card has a checkbox for selection

#### Scenario: Select all
- **WHEN** a user clicks "Select all" checkbox in the header
- **THEN** all visible items are selected

#### Scenario: Deselect all
- **WHEN** a user clicks "Select all" again
- **THEN** all items are deselected

#### Scenario: Selection count
- **WHEN** items are selected
- **THEN** a floating action bar shows the count of selected items (e.g., "5 selected")

### Requirement: Bulk move to stage
The system SHALL allow moving multiple selected applications to a specific pipeline stage.

#### Scenario: Bulk move via action bar
- **WHEN** a user selects applications and clicks "Move to Stage"
- **THEN** a dropdown shows available stages in the pipeline
- **AND** selecting a stage and confirming moves all selected applications

#### Scenario: Bulk move with email templates
- **WHEN** the target stage has an email template configured (Phase 2)
- **THEN** a confirmation dialog shows "Send email to all X candidates?" with Send/Skip options

#### Scenario: Bulk move in single transaction
- **WHEN** a bulk move is executed
- **THEN** all moves happen in a single database transaction
- **AND** if any move fails, all moves are rolled back

### Requirement: Bulk mark as reviewed
The system SHALL allow marking multiple applications as reviewed or unreviewed.

#### Scenario: Bulk mark reviewed
- **WHEN** a user selects applications and clicks "Mark as Reviewed"
- **THEN** all selected applications have `reviewed` set to `true`

#### Scenario: Bulk mark unreviewed
- **WHEN** a user selects reviewed applications and clicks "Mark as New"
- **THEN** all selected applications have `reviewed` set to `false`

### Requirement: Bulk delete
The system SHALL allow deleting multiple selected candidates.

#### Scenario: Bulk delete confirmation
- **WHEN** a user selects candidates and clicks "Delete"
- **THEN** a confirmation dialog asks "Delete X candidates? This cannot be undone."

#### Scenario: Bulk delete confirmed
- **WHEN** the user confirms bulk delete
- **THEN** all selected candidates and their applications, notes, and scorecards are deleted
- **AND** a summary is shown: "X candidates deleted"

#### Scenario: Bulk delete with admin-only restriction
- **WHEN** a member attempts bulk delete
- **THEN** the action is denied (Phase 2 RBAC)

### Requirement: Bulk send email
The system SHALL allow sending a custom email to multiple selected candidates.

#### Scenario: Bulk email composer
- **WHEN** a user selects candidates and clicks "Send Email"
- **THEN** an email composer opens with subject and body fields
- **AND** variables like `{candidate_name}` are interpolated per recipient

#### Scenario: Bulk email send
- **WHEN** the user confirms sending
- **THEN** personalized emails are sent to each selected candidate
- **AND** a summary is shown: "X emails sent"

#### Scenario: Bulk email with missing emails
- **WHEN** some selected candidates have no email address
- **THEN** those candidates are skipped
- **AND** the summary notes "X sent, Y skipped (no email)"

### Requirement: Floating action bar
The system SHALL display a floating action bar when items are selected.

#### Scenario: Action bar visibility
- **WHEN** one or more items are selected
- **THEN** a floating bar appears at the bottom of the screen with available bulk actions

#### Scenario: Action bar dismissal
- **WHEN** the user clicks "Clear selection" or deselects all items
- **THEN** the floating action bar disappears
