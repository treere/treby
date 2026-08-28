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
The system SHALL allow moving multiple selected applications to a specific pipeline stage. The stages offered SHALL come from the job's effective pipeline (explicit pipeline if assigned, otherwise the tenant's default pipeline). The bulk action bar controls SHALL be rendered inside a form so change/submit events reach the server without client-side errors.

#### Scenario: Bulk move via action bar
- **WHEN** a user selects applications and clicks "Move to Stage"
- **THEN** a dropdown shows available stages in the pipeline
- **AND** selecting a stage and confirming moves all selected applications

#### Scenario: Bulk move controls inside a form
- **WHEN** a user selects candidates on the pipeline board and opens the bulk action bar
- **THEN** the stage selector and move button are rendered inside a form element with `phx-change` / `phx-submit` wiring
- **AND** no "form events require the input to be inside a form" error is raised in the browser console

#### Scenario: Bulk move stage list uses effective pipeline
- **WHEN** a user opens the bulk action bar on a pipeline board for a job
- **THEN** the dropdown lists the stages of the job's effective pipeline, including a job with no explicit pipeline (falling back to the tenant's default pipeline)

#### Scenario: Bulk move with no stages available
- **WHEN** the effective pipeline has no stages
- **THEN** the "Move to Stage" action is disabled instead of showing an empty dropdown

#### Scenario: Bulk move with message templates
- **WHEN** the target stage has a message template configured
- **THEN** a confirmation dialog shows "Send message to all X candidates?" with Send/Skip options

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

### Requirement: Bulk send message
The system SHALL allow sending a custom message to multiple selected candidates, either immediately or scheduled, through their portal conversations.

#### Scenario: Bulk message composer
- **WHEN** a user selects candidates and clicks "Send Message"
- **THEN** a message composer opens with subject and body fields
- **AND** variables like `{candidate_name}` are interpolated per recipient
- **AND** the composer includes immediate send and schedule options

#### Scenario: Composer fields update without errors
- **WHEN** a user types in the subject, body, date, or time fields of the bulk message composer
- **THEN** each change is sent to the server and reflected in the composer
- **AND** no "form events require the input to be inside a form" error is raised

#### Scenario: Enter in the composer does not reload the page
- **WHEN** a user presses Enter while typing in a bulk message composer text field
- **THEN** the page does not reload or navigate
- **AND** the typed content is preserved

#### Scenario: Bulk message send immediate
- **WHEN** the user confirms sending immediately
- **THEN** a personalized message is posted to each selected candidate's conversation
- **AND** a summary is shown: "X messages sent"

#### Scenario: Bulk message send scheduled
- **WHEN** the user schedules the bulk send
- **THEN** personalized messages are created as scheduled records for each candidate
- **AND** a summary is shown: "X messages scheduled"
- **AND** the messages appear in the queue

#### Scenario: Bulk message with no conversation
- **WHEN** some selected candidates have no conversation for the target application
- **THEN** a conversation is created for each before the message is posted
- **AND** the summary notes "X sent/scheduled, Y conversations created"

### Requirement: Bulk send with schedule
The system SHALL allow users to schedule bulk message sends for a future time.

#### Scenario: Schedule option in bulk composer
- **WHEN** a user selects candidates and opens the bulk message composer
- **THEN** the composer includes a "Schedule for later" option alongside "Send now"

#### Scenario: Bulk schedule creates individual records
- **WHEN** a user schedules a bulk message for 50 candidates
- **THEN** 50 individual scheduled message records are created
- **AND** each record has its own Oban job for independent execution
- **AND** each appears individually in the message queue

#### Scenario: Bulk schedule with jitter
- **WHEN** a user enables jitter on a bulk schedule
- **THEN** each message gets an independent random offset within the jitter range
- **AND** the messages are distributed across the jitter window

### Requirement: Floating action bar
The system SHALL display a floating action bar when items are selected.

#### Scenario: Action bar visibility
- **WHEN** one or more items are selected
- **THEN** a floating bar appears at the bottom of the screen with available bulk actions

#### Scenario: Action bar dismissal
- **WHEN** the user clicks "Clear selection" or deselects all items
- **THEN** the floating action bar disappears
