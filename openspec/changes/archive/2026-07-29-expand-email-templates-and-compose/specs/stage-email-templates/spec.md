## MODIFIED Requirements

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
The system SHALL offer to send a templated email when a candidate is moved to a stage with a configured template, AND automatically send it when the notification is enabled.

#### Scenario: Email confirmation dialog
- **WHEN** a user moves a candidate to a stage that has an email template
- **THEN** a confirmation dialog is shown with the email preview (subject and body with variables resolved)
- **AND** the user can choose to send the email or skip

#### Scenario: Skip email
- **WHEN** the user clicks "Skip" in the confirmation dialog
- **THEN** the candidate is moved to the new stage without sending an email

#### Scenario: Send email
- **WHEN** the user clicks "Send" in the confirmation dialog
- **THEN** the email is sent to the candidate
- **AND** the candidate is moved to the new stage

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

### Requirement: View email template preview
The system SHALL show a preview of email templates in the settings page.

#### Scenario: Preview with sample data
- **WHEN** an admin views the email template settings
- **THEN** a preview of each template is shown with sample variable values
