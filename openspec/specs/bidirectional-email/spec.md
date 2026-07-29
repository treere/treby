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

### Requirement: Display email threads
The system SHALL display email threads on the candidate profile page.

#### Scenario: Thread list
- **WHEN** a user views a candidate profile
- **THEN** all email threads for that candidate are listed with subject, last message date, and message count

#### Scenario: Thread detail
- **WHEN** a user clicks on an email thread
- **THEN** the full conversation is displayed in chronological order
- **AND** each message shows direction (inbound/outbound), sender, recipient, date, and body

#### Scenario: Inbound message styling
- **WHEN** a message is from the candidate (inbound)
- **THEN** it is visually distinguished (e.g., different background color, left-aligned)

#### Scenario: Outbound message styling
- **WHEN** a message was sent from Treby (outbound)
- **THEN** it is visually distinguished (e.g., different background color, right-aligned)

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

### Requirement: Email thread metadata
The system SHALL store metadata for email messages.

#### Scenario: Message fields
- **WHEN** an email message is stored
- **THEN** it includes: direction, from address, to address, subject, body (text), html_body, sent_at/received_at

#### Scenario: Thread ordering
- **WHEN** messages in a thread are displayed
- **THEN** they are ordered chronologically (oldest first)

### Requirement: Email delivery for outbound
The system SHALL send outbound emails via Swoosh with proper threading headers.

#### Scenario: Threading headers
- **WHEN** a reply is sent
- **THEN** the email includes `In-Reply-To` and `References` headers matching the original message
- **AND** email clients display it as part of the same conversation
