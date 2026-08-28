## REMOVED Requirements

### Requirement: Schedule email for future delivery
**Reason**: Scheduling now applies to portal messages instead of emails.
**Migration**: See ADDED "Schedule message for future delivery".

### Requirement: Edit scheduled email
**Reason**: Editing applies to scheduled portal messages.
**Migration**: See ADDED "Edit scheduled message".

### Requirement: Cancel scheduled email
**Reason**: Cancellation applies to scheduled portal messages.
**Migration**: See ADDED "Cancel scheduled message".

### Requirement: Force-send cancelled email
**Reason**: Force-send applies to cancelled scheduled messages.
**Migration**: See ADDED "Force-send cancelled message".

### Requirement: View email history
**Reason**: The queue page now tracks scheduled messages instead of emails.
**Migration**: See ADDED "View scheduled message history".

### Requirement: Retry failed email
**Reason**: Retry applies to failed scheduled messages.
**Migration**: See ADDED "Retry failed message".

### Requirement: Oban delivery with retry
**Reason**: Delivery retry applies to scheduled messages via the `SendScheduledMessage` worker.
**Migration**: See ADDED "Oban delivery with retry".

### Requirement: Queue page
**Reason**: The queue management page tracks scheduled portal messages.
**Migration**: See ADDED "Message queue page".

## ADDED Requirements

### Requirement: Schedule message for future delivery
The system SHALL allow users to schedule a portal message for delivery at a future time across eligible flows (compose, reply, stage move, bulk).

#### Scenario: Schedule with preset
- **WHEN** a user composes a portal message and selects "Schedule for later"
- **AND** clicks a preset like "Tomorrow 9:00"
- **THEN** the message is saved in `scheduled_messages` with status "scheduled" and send_at set to tomorrow at 09:00

#### Scenario: Schedule with custom date/time
- **WHEN** a user selects "Custom" in the schedule picker
- **AND** chooses a date and time
- **THEN** the message is scheduled for that exact date and time

#### Scenario: Schedule and then send immediately from queue
- **WHEN** a user views the queue and clicks "Send Now" on a scheduled message
- **THEN** the message is posted immediately
- **AND** its status is updated to "sent"

### Requirement: Edit scheduled message
The system SHALL allow users to edit scheduled messages before they are sent.

#### Scenario: Edit body and time
- **WHEN** a user opens the edit modal for a scheduled message
- **THEN** they can modify the message body and the scheduled date and time

#### Scenario: Edit does not change recipient
- **WHEN** a user edits a scheduled message
- **THEN** the recipient conversation is not editable

#### Scenario: Edited message sends at new time
- **WHEN** a user saves edits to a scheduled message
- **THEN** the Oban job is rescheduled for the updated time

### Requirement: Cancel scheduled message
The system SHALL allow users to cancel a scheduled message before it is posted.

#### Scenario: Cancel from queue
- **WHEN** a user clicks "Cancel" on a queued message
- **THEN** the message status is set to "cancelled"

#### Scenario: Cancelled message is not posted
- **WHEN** the Oban worker executes for a cancelled message
- **THEN** it detects the cancelled status and does not post the message

### Requirement: Force-send cancelled message
The system SHALL allow users to immediately post a previously cancelled message.

#### Scenario: Send cancelled message
- **WHEN** a user clicks "Send Now" on a cancelled message
- **THEN** the message is posted immediately
- **AND** its status is updated to "sent"

### Requirement: View scheduled message history
The system SHALL provide a history of all posted, failed, and cancelled scheduled messages.

#### Scenario: Posted tab
- **WHEN** a user views the "Posted" tab in the message queue page
- **THEN** they see all successfully posted messages with recipient, body, sent_at, and type

#### Scenario: Failed tab
- **WHEN** a user views the "Failed" tab
- **THEN** they see all messages that failed after exhausting retries
- **AND** each entry shows the error reason and last failure time

#### Scenario: Cancelled tab
- **WHEN** a user views the "Cancelled" tab
- **THEN** they see all cancelled messages with recipient, body, and cancelled_at

### Requirement: Retry failed message
The system SHALL allow users to retry delivery of failed scheduled messages.

#### Scenario: Retry from queue
- **WHEN** a user clicks "Retry" on a failed message
- **THEN** a new Oban job is inserted for immediate execution
- **AND** the message status is reset to "scheduled"

### Requirement: Oban delivery with retry
The system SHALL deliver scheduled messages via Oban with automatic retry on failure, using the `SendScheduledMessage` worker.

#### Scenario: Successful delivery
- **WHEN** the Oban worker executes and the message is posted to the conversation
- **THEN** the scheduled message status is updated to "sent"
- **AND** the sent_at timestamp is recorded
- **AND** the conversation's `last_message_at` and status are updated

#### Scenario: Transient failure retried
- **WHEN** the first delivery attempt fails with a transient error
- **THEN** Oban retries with exponential backoff (1min, 4min, 15min, 60min)
- **AND** the retry_count is incremented on each attempt

#### Scenario: All retries exhausted
- **WHEN** all 5 delivery attempts fail
- **THEN** the message status is set to "failed"
- **AND** the error reason from the last attempt is stored
- **AND** the message appears in the "Failed" tab for manual retry

#### Scenario: Cancel during retry window
- **WHEN** a user cancels a message while it is between retry attempts
- **THEN** the next Oban execution detects the cancelled status and does not attempt posting

### Requirement: Message queue page
The system SHALL provide a dedicated message queue management page at `/app/messages-queue`.

#### Scenario: Queue page accessible from navigation
- **WHEN** a user navigates to `/app/messages-queue`
- **THEN** they see the queue management interface with tabbed views

#### Scenario: Queue counts displayed
- **WHEN** a user views the queue page
- **THEN** each tab shows the count of messages in that status

#### Scenario: Bulk actions on queue
- **WHEN** a user selects multiple queued messages
- **THEN** they can bulk-send or bulk-cancel the selected messages