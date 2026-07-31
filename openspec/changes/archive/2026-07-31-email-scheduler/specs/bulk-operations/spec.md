## ADDED Requirements

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

## MODIFIED Requirements

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
