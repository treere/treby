# Bidirectional Email

## Purpose

Enable two-way email communication between recruiters and candidates within Treby, so hiring conversations don't happen in scattered email clients.

## Requirements

### Requirement: Receive candidate replies
The system SHALL receive and store inbound emails from candidates.

#### Scenario: Inbound email parsing
- **WHEN** a candidate replies to an interview notification email
- **THEN** the inbound email is received via webhook (Postmark/SendGrid)
- **AND** the email is parsed and stored in the appropriate thread

#### Scenario: Match to existing thread
- **WHEN** an inbound email has a subject line matching an existing thread
- **THEN** the email is appended to that thread

#### Scenario: New thread creation
- **WHEN** an inbound email doesn't match an existing thread
- **THEN** a new thread is created for the candidate

#### Scenario: Match to candidate by email
- **WHEN** an inbound email is received from a known candidate email address
- **THEN** the email is associated with that candidate's profile

#### Scenario: Unknown sender
- **WHEN** an inbound email is from an unknown email address
- **THEN** the email is logged but not associated with any candidate

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

### Requirement: Reply with schedule option
The system SHALL allow users to schedule a reply in an email thread.

#### Scenario: Reply form has schedule option
- **WHEN** a user clicks "Reply" in an email thread
- **THEN** the reply form includes the same schedule option as compose

#### Scenario: Scheduled reply appears in thread
- **WHEN** a user schedules a reply
- **THEN** the reply appears in the thread as a scheduled message with pending indicator

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

#### Scenario: Thread ordering
- **WHEN** messages in a thread are displayed
- **THEN** they are ordered chronologically (oldest first)

### Requirement: Email delivery for outbound
The system SHALL send outbound emails via Swoosh with proper threading headers.

#### Scenario: Threading headers
- **WHEN** a reply is sent
- **THEN** the email includes `In-Reply-To` and `References` headers matching the original message
- **AND** email clients display it as part of the same conversation
