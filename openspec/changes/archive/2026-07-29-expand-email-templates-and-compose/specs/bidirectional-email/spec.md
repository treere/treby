## MODIFIED Requirements

### Requirement: Reply to email
The system SHALL allow recruiters to reply to candidate emails from within Treby.

#### Scenario: Reply button
- **WHEN** a user views an email thread
- **THEN** a "Reply" button is shown at the bottom of the thread

#### Scenario: Reply composer
- **WHEN** a user clicks "Reply"
- **THEN** an inline composer opens with the previous message quoted
- **AND** the composer has subject (pre-filled), body, and send fields

#### Scenario: Send reply
- **WHEN** the user clicks "Send"
- **THEN** the email is sent via Swoosh to the candidate
- **AND** the message is appended to the thread as an outbound message

#### Scenario: Reply to thread with no prior messages
- **WHEN** a thread has only inbound messages (no prior replies)
- **THEN** the reply is sent and added as the first outbound message

## ADDED Requirements

### Requirement: Compose new email thread
The system SHALL allow recruiters to start a new email conversation with a candidate from the candidate profile page.

#### Scenario: Compose button
- **WHEN** a user views a candidate profile
- **THEN** a "Compose Email" button is shown in the Email History section

#### Scenario: Compose form
- **WHEN** a user clicks "Compose Email"
- **THEN** an inline form opens with subject and body fields
- **AND** the subject field is editable (not pre-filled)

#### Scenario: Send new email
- **WHEN** the user fills in the subject and body and clicks "Send"
- **THEN** a new email thread is created for the candidate
- **AND** the email is sent via Swoosh to the candidate's email address
- **AND** the outbound message is stored in the thread
- **AND** the thread list is refreshed to show the new thread

#### Scenario: Cancel compose
- **WHEN** the user clicks "Cancel" in the compose form
- **THEN** the form closes without sending any email

#### Scenario: Compose validation
- **WHEN** the user clicks "Send" with an empty subject or body
- **THEN** the form shows a validation error and no email is sent
