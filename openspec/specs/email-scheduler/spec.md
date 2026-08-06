# Email Scheduler

## Purpose

Allow users to schedule email delivery for a future time across compose, reply, bulk send, and stage move flows, and manage all scheduled, sent, failed, and cancelled emails from a dedicated queue page with reliable Oban-based delivery and retry.

## Requirements

### Requirement: Schedule email for future delivery
The system SHALL allow users to schedule email delivery for a future time across all eligible flows (compose, reply, bulk send, stage move).

#### Scenario: Schedule with preset
- **WHEN** a user composes an email and selects "Schedule for later"
- **AND** clicks a preset like "Tomorrow 9:00"
- **THEN** the email is saved with status "scheduled" and scheduled_at set to tomorrow at 09:00
- **AND** the email appears in the candidate's thread with a pending indicator

#### Scenario: Schedule with custom date/time
- **WHEN** a user selects "Custom" in the schedule picker
- **AND** chooses a date and time
- **THEN** the email is scheduled for that exact date and time

#### Scenario: Schedule with jitter
- **WHEN** a user enables the jitter toggle and specifies ±N minutes
- **THEN** the effective send time is randomized within that range
- **AND** the queue UI shows the original requested time (not the jittered time)

#### Scenario: Schedule and then send immediately from queue
- **WHEN** a user views the queue and clicks "Send Now" on a scheduled email
- **THEN** the email is sent immediately
- **AND** its status is updated to "sent"

### Requirement: Edit scheduled email
The system SHALL allow users to edit scheduled emails before they are sent.

#### Scenario: Edit subject and body
- **WHEN** a user opens the edit modal for a scheduled email
- **THEN** they can modify the subject and body fields

#### Scenario: Edit schedule time
- **WHEN** a user edits a scheduled email
- **THEN** they can change the scheduled date and time

#### Scenario: Edit does not change recipient
- **WHEN** a user edits a scheduled email
- **THEN** the recipient field is not editable

#### Scenario: Edited email sends at new time
- **WHEN** a user saves edits to a scheduled email
- **THEN** the Oban job is rescheduled for the updated time
- **AND** the thread message preview updates to reflect new content

#### Scenario: Save with minute-only time input
- **WHEN** a user saves an edited scheduled email with a time entered as `HH:MM` (no seconds)
- **THEN** the email is saved without error
- **AND** the scheduled time is interpreted as `HH:MM:00`
- **AND** the Oban job is rescheduled for that time

#### Scenario: Invalid time does not crash
- **WHEN** a user saves an edited scheduled email with a malformed time value
- **THEN** a validation error is shown
- **AND** the page does not crash or disconnect

### Requirement: Cancel scheduled email
The system SHALL allow users to cancel a scheduled email before it is sent.

#### Scenario: Cancel from queue
- **WHEN** a user clicks "Cancel" on a queued email
- **THEN** the email status is set to "cancelled"
- **AND** the thread message shows as cancelled

#### Scenario: Cancelled email is not sent
- **WHEN** the Oban worker executes for a cancelled email
- **THEN** it detects the cancelled status and does not send the email

#### Scenario: Delete cancelled email
- **WHEN** a user clicks "Delete" on a cancelled email
- **THEN** the email is permanently removed from the database
- **AND** the thread message is also removed

### Requirement: Force-send cancelled email
The system SHALL allow users to immediately send a previously cancelled email.

#### Scenario: Send cancelled email
- **WHEN** a user clicks "Send Now" on a cancelled email
- **THEN** the email is sent immediately
- **AND** its status is updated to "sent"

### Requirement: View email history
The system SHALL provide a history of all sent, failed, and cancelled emails.

#### Scenario: Sent tab shows delivered emails
- **WHEN** a user views the "Sent" tab in the email queue page
- **THEN** they see all successfully sent emails with recipient, subject, sent_at, and email type

#### Scenario: Failed tab shows delivery failures
- **WHEN** a user views the "Failed" tab
- **THEN** they see all emails that failed after exhausting retries
- **AND** each entry shows the error reason and last failure time

#### Scenario: Cancelled tab shows cancelled emails
- **WHEN** a user views the "Cancelled" tab
- **THEN** they see all cancelled emails with recipient, subject, and cancelled_at

### Requirement: Retry failed email
The system SHALL allow users to retry delivery of failed emails.

#### Scenario: Retry from queue
- **WHEN** a user clicks "Retry" on a failed email
- **THEN** a new Oban job is inserted for immediate execution
- **AND** the email status is reset to "scheduled"

#### Scenario: Delete failed email
- **WHEN** a user clicks "Delete" on a failed email
- **THEN** the email is permanently removed from the database
- **AND** the thread message is also removed

### Requirement: Oban delivery with retry
The system SHALL deliver scheduled emails via Oban with automatic retry on failure.

#### Scenario: Successful delivery
- **WHEN** the Oban worker executes and Mailer.deliver returns success
- **THEN** the email status is updated to "sent"
- **AND** the thread message status is updated to "sent"
- **AND** the sent_at timestamp is recorded

#### Scenario: Transient failure retried
- **WHEN** the first delivery attempt fails with a transient error
- **THEN** Oban retries with exponential backoff (1min, 4min, 15min, 60min)
- **AND** the retry_count is incremented on each attempt

#### Scenario: All retries exhausted
- **WHEN** all 5 delivery attempts fail
- **THEN** the email status is set to "failed"
- **AND** the error reason from the last attempt is stored
- **AND** the email appears in the "Failed" tab for manual retry

#### Scenario: Cancel during retry window
- **WHEN** a user cancels an email while it is between retry attempts
- **THEN** the next Oban execution detects the cancelled status and does not attempt delivery

### Requirement: Queue page
The system SHALL provide a dedicated email queue management page at `/app/email-queue`.

#### Scenario: Queue page accessible from navigation
- **WHEN** a user navigates to `/app/email-queue`
- **THEN** they see the queue management interface with tabbed views

#### Scenario: Queue counts displayed
- **WHEN** a user views the queue page
- **THEN** each tab shows the count of emails in that status

#### Scenario: Bulk actions on queue
- **WHEN** a user selects multiple queued emails
- **THEN** they can bulk-send or bulk-cancel the selected emails
