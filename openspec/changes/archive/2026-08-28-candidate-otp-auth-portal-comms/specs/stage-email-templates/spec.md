## REMOVED Requirements

### Requirement: Define email templates
**Reason**: Stage templates become in-app message templates delivered via portal conversations, not emails.
**Migration**: Templates are configured per stage type and rendered into portal messages.

### Requirement: Template variables
**Reason**: Variable interpolation still applies but in the context of portal messages; superseded by the new message template requirements.
**Migration**: See the ADDED template variable requirement below.

### Requirement: Optional email on stage move
**Reason**: No email is sent on stage moves; the templated content is posted as a portal message.
**Migration**: See the ADDED "Message on stage move" requirement.

### Requirement: Optional schedule on stage move email
**Reason**: Scheduling now applies to portal messages via `scheduled_messages`.
**Migration**: See `email-scheduler` (renamed message scheduling) and the ADDED "Schedule message on stage move" requirement.

### Requirement: Email delivery
**Reason**: Stage content is no longer delivered by email.
**Migration**: The rendered message is inserted into the candidate's conversation by the scheduling worker.

### Requirement: View email template preview
**Reason**: The preview still exists but shows a message body instead of an email.
**Migration**: See the ADDED "View message template preview" requirement.

## ADDED Requirements

### Requirement: Define message templates
The system SHALL allow admins to configure message templates per stage type. Templates MAY be created for any of the following stage types: `new`, `interview`, `offer`, `hired`, `rejected`.

#### Scenario: Create message template
- **WHEN** an admin creates a message template for a stage type
- **THEN** the template is saved with a name, subject line, message body, and target stage type

#### Scenario: One template per stage type
- **WHEN** an admin creates a second template for the same stage type
- **THEN** the existing template is replaced (upsert behavior)

#### Scenario: Edit message template
- **WHEN** an admin edits a message template
- **THEN** the template is updated and future messages use the new content

#### Scenario: Delete message template
- **WHEN** an admin deletes a message template
- **THEN** no templated message is sent when candidates move to that stage type

### Requirement: Template variables
The system SHALL support variable interpolation in message templates.

#### Scenario: Available variables
- **WHEN** an admin writes a message template
- **THEN** they can use the following variables: `{candidate_name}`, `{job_title}`, `{company_name}`, `{stage_name}`, `{recruiter_name}`

#### Scenario: Variable interpolation on send
- **WHEN** a message is posted from a template
- **THEN** all variables are replaced with actual values from the candidate, job, and tenant

#### Scenario: Recruiter name populated
- **WHEN** a stage change message is triggered by a user action
- **THEN** `{recruiter_name}` is replaced with the name of the user who moved the candidate

#### Scenario: Missing variable handling
- **WHEN** a variable references a field that is empty or missing
- **THEN** the variable is replaced with an empty string

### Requirement: Message on stage move
The system SHALL offer to post a templated message when a candidate is moved to a stage with a configured template, giving the user the option to send immediately, schedule, or skip.

#### Scenario: Stage move confirmation dialog
- **WHEN** a user moves a candidate to a stage that has a message template
- **THEN** a confirmation dialog is shown with the message preview (subject and body with variables resolved)
- **AND** the user can choose to send the message immediately, schedule it, or skip

#### Scenario: Skip message
- **WHEN** the user clicks "Skip" in the confirmation dialog
- **THEN** the candidate is moved to the new stage without posting a message

#### Scenario: Send message immediately
- **WHEN** the user clicks "Send Now" in the confirmation dialog
- **THEN** the message is posted to the candidate's conversation immediately
- **AND** the candidate is moved to the new stage

#### Scenario: Schedule message
- **WHEN** the user clicks "Schedule" in the confirmation dialog
- **THEN** a schedule picker is shown
- **AND** after confirming the time, the candidate is moved to the new stage
- **AND** the message is saved as a scheduled message

#### Scenario: No template configured
- **WHEN** a user moves a candidate to a stage with no message template
- **THEN** the candidate is moved without any message prompt

#### Scenario: Automatic stage change message
- **WHEN** a user moves a candidate to a stage that has a message template
- **AND** the `stage_change_candidate` notification is enabled for the tenant
- **THEN** the stage change system message is posted to the conversation automatically
- **AND** the user can still choose to add the templated message or skip

### Requirement: Schedule message on stage move
The system SHALL allow users to schedule the stage move message for a future time instead of posting it immediately.

#### Scenario: Stage move dialog has schedule option
- **WHEN** a user moves a candidate to a stage with a message template
- **THEN** the confirmation dialog includes "Send now", "Schedule", and "Skip" options

#### Scenario: Schedule stage message
- **WHEN** the user selects "Schedule" in the stage move dialog
- **THEN** the schedule picker is shown with presets and custom date/time
- **AND** the candidate is moved to the new stage immediately
- **AND** the message is scheduled for the chosen time

#### Scenario: Stage message scheduled appears in queue
- **WHEN** a stage move message is scheduled
- **THEN** it appears in the message queue with type "stage_change"
- **AND** the queue entry includes the candidate and job reference

### Requirement: Message delivery
The system SHALL post stage-based messages to the candidate's conversation using the scheduled-message worker for future delivery.

#### Scenario: Message posted successfully
- **WHEN** the user confirms posting a stage-based message
- **THEN** the message is inserted into the candidate's conversation for that application
- **AND** the conversation's `last_message_at` and status are updated

#### Scenario: Scheduled delivery
- **WHEN** a stage-based message is scheduled
- **THEN** the `SendScheduledMessage` Oban worker posts it at the scheduled time with the same retry/backoff cycle used for emails

#### Scenario: Delivery failure
- **WHEN** scheduled message delivery fails
- **THEN** the candidate is still moved to the new stage
- **AND** the failure is logged in the activity audit trail (non-blocking)

### Requirement: View message template preview
The system SHALL show a preview of message templates in the settings page.

#### Scenario: Preview with sample data
- **WHEN** an admin views the message template settings
- **THEN** a preview of each template is shown with sample variable values