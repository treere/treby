## RENAMED Requirements

### Requirement: Bulk send email
FROM: Bulk send email
TO: Bulk send message

## MODIFIED Requirements

### Requirement: Bulk move to stage
The system SHALL allow moving multiple selected applications to a specific pipeline stage.

#### Scenario: Bulk move via action bar
- **WHEN** a user selects applications and clicks "Move to Stage"
- **THEN** a dropdown shows available stages in the pipeline
- **AND** selecting a stage and confirming moves all selected applications

#### Scenario: Bulk move with message templates
- **WHEN** the target stage has a message template configured
- **THEN** a confirmation dialog shows "Send message to all X candidates?" with Send/Skip options

#### Scenario: Bulk move in single transaction
- **WHEN** a bulk move is executed
- **THEN** all moves happen in a single database transaction
- **AND** if any move fails, all moves are rolled back

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