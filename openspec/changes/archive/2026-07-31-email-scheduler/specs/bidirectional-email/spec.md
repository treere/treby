## ADDED Requirements

### Requirement: Email messages have a status
The system SHALL track the delivery status of each outbound email message in a thread.

#### Scenario: Immediate send creates sent message
- **WHEN** a user sends an email immediately
- **THEN** the message is created with status "sent"
- **AND** it appears normally in the thread

#### Scenario: Scheduled send creates scheduled message
- **WHEN** a user schedules an email for later
- **THEN** the message is created with status "scheduled"
- **AND** it appears in the thread with a pending/scheduled indicator
- **AND** it includes the scheduled time

#### Scenario: Scheduled message becomes sent
- **WHEN** the Oban worker delivers a scheduled email successfully
- **THEN** the message status is updated to "sent"
- **AND** the scheduled indicator is removed from the thread

#### Scenario: Scheduled message becomes cancelled
- **WHEN** a user cancels a scheduled email from the queue
- **THEN** the message status is updated to "cancelled"
- **AND** it appears in the thread with a cancelled indicator

### Requirement: Compose email with schedule option
The system SHALL allow users to schedule a new email when composing from the candidate profile.

#### Scenario: Compose form has schedule option
- **WHEN** a user opens the compose email form
- **THEN** the form includes a "Schedule for later" option alongside "Send now"

#### Scenario: Schedule compose with presets
- **WHEN** a user chooses "Schedule for later"
- **THEN** they see quick presets (Tomorrow 9:00, Tomorrow 14:00, Next Monday)
- **AND** a custom date/time picker as fallback
- **AND** a jitter toggle

#### Scenario: Schedule compose saves to queue
- **WHEN** a user fills in subject and body and schedules the email
- **THEN** a scheduled email record is created
- **AND** a thread message is created with status "scheduled"
- **AND** the email appears in the email queue

### Requirement: Reply with schedule option
The system SHALL allow users to schedule a reply in an email thread.

#### Scenario: Reply form has schedule option
- **WHEN** a user clicks "Reply" in an email thread
- **THEN** the reply form includes the same schedule option as compose

#### Scenario: Scheduled reply appears in thread
- **WHEN** a user schedules a reply
- **THEN** the reply appears in the thread as a scheduled message with pending indicator

## MODIFIED Requirements

### Requirement: Send reply
The system SHALL allow recruiters to reply to candidate emails from within Treby, either immediately or scheduled.

#### Scenario: Send reply immediately
- **WHEN** the user clicks "Send" (immediate mode)
- **THEN** the email is sent via Swoosh to the candidate
- **AND** the message is appended to the thread as an outbound message with status "sent"

#### Scenario: Send reply scheduled
- **WHEN** the user clicks "Schedule" with a future time
- **THEN** the email is saved as a scheduled email
- **AND** a thread message is created with status "scheduled"

### Requirement: Compose new email thread
The system SHALL allow recruiters to start a new email conversation with a candidate, either immediately or scheduled.

#### Scenario: Send new email immediately
- **WHEN** the user fills in the subject and body and clicks "Send" (immediate mode)
- **THEN** a new email thread is created for the candidate
- **AND** the email is sent via Swoosh to the candidate's email address
- **AND** the outbound message is stored in the thread with status "sent"

#### Scenario: Send new email scheduled
- **WHEN** the user fills in the subject and body and clicks "Schedule"
- **THEN** a new email thread is created for the candidate
- **AND** the outbound message is stored in the thread with status "scheduled"
- **AND** a scheduled email record is created for future delivery

### Requirement: Email thread metadata
The system SHALL store metadata for email messages, including delivery status for outbound messages.

#### Scenario: Message fields
- **WHEN** an email message is stored
- **THEN** it includes: direction, from address, to address, subject, body (text), html_body, sent_at/received_at, status, scheduled_at (if applicable)
- **AND** outbound messages have a status of "sent", "scheduled", or "cancelled"

#### Scenario: Scheduled message display
- **WHEN** a thread contains a scheduled message
- **THEN** the message is displayed with a visual indicator (e.g., clock icon, dashed border)
- **AND** the scheduled time is shown
- **AND** the message is placed in chronological order at its scheduled position
