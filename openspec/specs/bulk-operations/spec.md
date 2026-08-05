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

### Requirement: Bulk compare
The system SHALL allow comparing 2-3 selected candidates side-by-side from the bulk action bar.

#### Scenario: Compare action in action bar
- **WHEN** a user selects 2-3 candidates in the candidates list and chooses "Compare" from the action bar dropdown
- **THEN** a "Compare" confirm button is shown

#### Scenario: Compare navigates to comparison view
- **WHEN** a user clicks "Compare"
- **THEN** the system navigates to the comparison view with the selected candidate ids in the URL

### Requirement: Bulk send email
The system SHALL allow sending a custom email to multiple selected candidates, either immediately or scheduled.

#### Scenario: Bulk email composer
- **WHEN** a user selects candidates and clicks "Send Email"
- **THEN** an email composer opens with subject and body fields
- **AND** variables like `{candidate_name}` are interpolated per recipient
- **AND** the composer includes immediate send and schedule options

#### Scenario: Bulk email send immediate
- **WHEN** the user confirms sending immediately
- **THEN** personalized emails are sent to each selected candidate
- **AND** a summary is shown: "X emails sent"

#### Scenario: Bulk email send scheduled
- **WHEN** the user schedules the bulk send
- **THEN** personalized emails are created as scheduled records for each candidate
- **AND** a summary is shown: "X emails scheduled"
- **AND** the emails appear in the queue

#### Scenario: Bulk email with missing emails
- **WHEN** some selected candidates have no email address
- **THEN** those candidates are skipped
- **AND** the summary notes "X sent/scheduled, Y skipped (no email)"

### Requirement: Bulk send with schedule
The system SHALL allow users to schedule bulk email sends for a future time.

#### Scenario: Schedule option in bulk composer
- **WHEN** a user selects candidates and opens the bulk email composer
- **THEN** the composer includes a "Schedule for later" option alongside "Send now"

#### Scenario: Bulk schedule creates individual records
- **WHEN** a user schedules a bulk email for 50 candidates
- **THEN** 50 individual scheduled email records are created
- **AND** each record has its own Oban job for independent execution
- **AND** each appears individually in the email queue

#### Scenario: Bulk schedule with jitter
- **WHEN** a user enables jitter on a bulk schedule
- **THEN** each email gets an independent random offset within the jitter range
- **AND** the emails are distributed across the jitter window

### Requirement: Floating action bar
The system SHALL display a floating action bar when items are selected.

#### Scenario: Action bar visibility
- **WHEN** one or more items are selected
- **THEN** a floating bar appears at the bottom of the screen with available bulk actions

#### Scenario: Action bar dismissal
- **WHEN** the user clicks "Clear selection" or deselects all items
- **THEN** the floating action bar disappears
