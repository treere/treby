## MODIFIED Requirements

### Requirement: Display email threads
The system SHALL display email threads on the candidate profile page. When the candidate portal is enabled, email threads are displayed as a secondary communication channel alongside in-platform conversations.

#### Scenario: Thread list
- **WHEN** a user views a candidate profile
- **THEN** all email threads for that candidate are listed with subject, last message date, and message count

#### Scenario: Thread detail
- **WHEN** a user clicks on an email thread
- **THEN** the full conversation is displayed in chronological order
- **AND** each message shows direction (inbound/outbound), sender, recipient, date, and body

#### Scenario: Email threads alongside conversations
- **WHEN** a user views a candidate profile that has both email threads and portal conversations
- **THEN** the "Email" tab shows email threads
- **AND** the "Conversations" tab shows portal conversations
- **AND** both tabs are accessible from the candidate profile

#### Scenario: Inbound message styling
- **WHEN** a message is from the candidate (inbound)
- **THEN** it is visually distinguished (e.g., different background color, left-aligned)

#### Scenario: Outbound message styling
- **WHEN** a message was sent from Treby (outbound)
- **THEN** it is visually distinguished (e.g., different background color, right-aligned)

### Requirement: Reply to email
The system SHALL allow recruiters to reply to candidate emails from within Treby, either immediately or scheduled. This remains available as a fallback for candidates who do not use the portal.

#### Scenario: Reply button
- **WHEN** a user views an email thread
- **THEN** a "Reply" button is shown at the bottom of the thread

#### Scenario: Reply composer
- **WHEN** a user clicks "Reply"
- **THEN** an inline composer opens with the previous message quoted
- **AND** the composer has subject (pre-filled), body, and send fields

#### Scenario: Send reply immediately
- **WHEN** the user clicks "Send" (immediate mode)
- **THEN** the email is sent via Swoosh to the candidate
- **AND** the message is appended to the thread as an outbound message with status "sent"

#### Scenario: Send reply scheduled
- **WHEN** the user clicks "Schedule" with a future time
- **THEN** the email is saved as a scheduled email
- **AND** a thread message is created with status "scheduled"

#### Scenario: Reply to thread with no prior messages
- **WHEN** a thread has only inbound messages (no prior replies)
- **THEN** the reply is sent and added as the first outbound message

### Requirement: Compose new email thread
The system SHALL allow recruiters to start a new email conversation with a candidate, either immediately or scheduled. When the portal is available, recruiters should prefer sending a portal message instead.

#### Scenario: Compose button
- **WHEN** a user views a candidate profile
- **THEN** a "Compose Email" button is shown in the Email History section

#### Scenario: Compose form
- **WHEN** a user clicks "Compose Email"
- **THEN** an inline form opens with subject and body fields
- **AND** the subject field is editable (not pre-filled)

#### Scenario: Send new email immediately
- **WHEN** the user fills in the subject and body and clicks "Send" (immediate mode)
- **THEN** a new email thread is created for the candidate
- **AND** the email is sent via Swoosh to the candidate's email address
- **AND** the outbound message is stored in the thread with status "sent"
- **AND** the thread list is refreshed to show the new thread

#### Scenario: Send new email scheduled
- **WHEN** the user fills in the subject and body and clicks "Schedule"
- **THEN** a new email thread is created for the candidate
- **AND** the outbound message is stored in the thread with status "scheduled"
- **AND** a scheduled email record is created for future delivery

#### Scenario: Cancel compose
- **WHEN** the user clicks "Cancel" in the compose form
- **THEN** the form closes without sending any email

#### Scenario: Compose validation
- **WHEN** the user clicks "Send" with an empty subject or body
- **THEN** the form shows a validation error and no email is sent
