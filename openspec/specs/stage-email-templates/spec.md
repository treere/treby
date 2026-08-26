# Stage-Based Email Templates

## Purpose

Allow admins to configure templated emails that are optionally sent when candidates move to specific pipeline stages, automating routine communications like rejections and advances.

## Requirements

### Requirement: Define email templates
The system SHALL allow admins to configure email templates per stage type. Templates MAY be created for any of the following stage types: `new`, `interview`, `offer`, `hired`, `rejected`.

#### Scenario: Create email template
- **WHEN** an admin creates an email template for a stage type
- **THEN** the template is saved with a name, subject line, HTML body, and target stage type

#### Scenario: One template per stage type
- **WHEN** an admin creates a second template for the same stage type
- **THEN** the existing template is replaced (upsert behavior)

#### Scenario: Edit email template
- **WHEN** an admin edits an email template
- **THEN** the template is updated and future emails use the new content

#### Scenario: Delete email template
- **WHEN** an admin deletes an email template
- **THEN** no email is sent when candidates move to that stage type

### Requirement: Template variables
The system SHALL support variable interpolation in email templates.

#### Scenario: Available variables
- **WHEN** an admin writes an email template
- **THEN** they can use the following variables: `{candidate_name}`, `{job_title}`, `{company_name}`, `{stage_name}`, `{recruiter_name}`

#### Scenario: Variable interpolation on send
- **WHEN** an email is sent from a template
- **THEN** all variables are replaced with actual values from the candidate, job, and tenant

#### Scenario: Recruiter name populated
- **WHEN** a stage change email is triggered by a user action
- **THEN** `{recruiter_name}` is replaced with the name of the user who moved the candidate

#### Scenario: Missing variable handling
- **WHEN** a variable references a field that is empty or missing
- **THEN** the variable is replaced with an empty string

### Requirement: Optional email on stage move
The system SHALL offer to send a templated email when a candidate is moved to a stage with a configured template, giving the user the option to send immediately, schedule, or skip. When the candidate portal is enabled, the email content defaults to a notification ping format.

#### Scenario: Email confirmation dialog
- **WHEN** a user moves a candidate to a stage that has an email template
- **THEN** a confirmation dialog is shown with the email preview (subject and body with variables resolved)
- **AND** the user can choose to send the email immediately, schedule it, or skip

#### Scenario: Ping format with portal
- **WHEN** a user moves a candidate to a stage with a configured email template
- **AND** the candidate has an active portal conversation
- **THEN** the email preview shows a short notification format: "{stage_name} for {job_title}" with a "View in Portal" button
- **AND** the user can still choose to send the full template, schedule, or skip

#### Scenario: Skip email
- **WHEN** the user clicks "Skip" in the confirmation dialog
- **THEN** the candidate is moved to the new stage without sending an email

#### Scenario: Send email immediately
- **WHEN** the user clicks "Send Now" in the confirmation dialog
- **THEN** the email is sent to the candidate immediately
- **AND** the candidate is moved to the new stage

#### Scenario: Schedule email
- **WHEN** the user clicks "Schedule" in the confirmation dialog
- **THEN** a schedule picker is shown
- **AND** after confirming the time, the candidate is moved to the new stage
- **AND** the email is saved as a scheduled email

#### Scenario: No template configured
- **WHEN** a user moves a candidate to a stage with no email template
- **THEN** the candidate is moved without any email prompt

#### Scenario: Automatic send when notification enabled
- **WHEN** a user moves a candidate to a stage that has an email template
- **AND** the `stage_change_candidate` notification is enabled for the tenant
- **THEN** the confirmation dialog is shown with a note that the email will be sent automatically
- **AND** the user can still choose to skip sending

#### Scenario: Automatic send via bulk move
- **WHEN** a user bulk-moves multiple candidates to a stage with an email template
- **AND** the `stage_change_candidate` notification is enabled
- **THEN** emails are sent to all candidates with configured email addresses
- **AND** a summary is shown: "X moved, Y emails sent"

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

### Requirement: Email delivery
The system SHALL send stage-based emails using the existing Swoosh infrastructure.

#### Scenario: Email sent successfully
- **WHEN** the user confirms sending a stage-based email
- **THEN** the email is delivered via Swoosh to the candidate's email address
- **AND** the email uses the tenant's sender configuration

#### Scenario: Email delivery failure
- **WHEN** email delivery fails
- **THEN** the candidate is still moved to the new stage
- **AND** an error is logged but not shown to the user (non-blocking)

#### Scenario: Delivery failure logging
- **WHEN** email delivery fails
- **THEN** the failure is logged in the activity audit trail with error details
- **AND** the stage move completes successfully

### Requirement: View email template preview
The system SHALL show a preview of email templates in the settings page.

#### Scenario: Preview with sample data
- **WHEN** an admin views the email template settings
- **THEN** a preview of each template is shown with sample variable values
