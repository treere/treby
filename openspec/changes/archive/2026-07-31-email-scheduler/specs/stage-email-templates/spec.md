## ADDED Requirements

### Requirement: Optional schedule on stage move email
The system SHALL allow users to schedule the stage change email for a future time instead of sending it immediately.

#### Scenario: Stage move dialog has schedule option
- **WHEN** a user moves a candidate to a stage with an email template
- **THEN** the confirmation dialog includes "Send now", "Schedule", and "Skip" options

#### Scenario: Schedule stage email
- **WHEN** the user selects "Schedule" in the stage move dialog
- **THEN** the schedule picker is shown with presets and custom date/time
- **AND** the candidate is moved to the new stage immediately
- **AND** the email is scheduled for the chosen time

#### Scenario: Stage email scheduled appears in queue
- **WHEN** a stage change email is scheduled
- **THEN** it appears in the email queue with email_type "stage_change"
- **AND** the queue entry includes the candidate and job reference

## MODIFIED Requirements

### Requirement: Optional email on stage move
The system SHALL offer to send a templated email when a candidate is moved to a stage with a configured template, giving the user the option to send immediately, schedule, or skip.

#### Scenario: Email confirmation dialog
- **WHEN** a user moves a candidate to a stage that has an email template
- **THEN** a confirmation dialog is shown with the email preview (subject and body with variables resolved)
- **AND** the user can choose to send the email immediately, schedule it, or skip

#### Scenario: Send email immediately
- **WHEN** the user clicks "Send Now" in the confirmation dialog
- **THEN** the email is sent to the candidate immediately
- **AND** the candidate is moved to the new stage

#### Scenario: Schedule email
- **WHEN** the user clicks "Schedule" in the confirmation dialog
- **THEN** a schedule picker is shown
- **AND** after confirming the time, the candidate is moved to the new stage
- **AND** the email is saved as a scheduled email

#### Scenario: Skip email
- **WHEN** the user clicks "Skip" in the confirmation dialog
- **THEN** the candidate is moved to the new stage without sending an email

#### Scenario: No template configured
- **WHEN** a user moves a candidate to a stage with no email template
- **THEN** the candidate is moved without any email prompt
