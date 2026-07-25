# Stage-Based Email Templates

## Purpose

Allow admins to configure templated emails that are optionally sent when candidates move to specific pipeline stages, automating routine communications like rejections and advances.

## Requirements

### Requirement: Define email templates
The system SHALL allow admins to configure email templates per stage type.

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

#### Scenario: Missing variable handling
- **WHEN** a variable references a field that is empty or missing
- **THEN** the variable is replaced with an empty string

### Requirement: Optional email on stage move
The system SHALL offer to send a templated email when a candidate is moved to a stage with a configured template.

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

### Requirement: View email template preview
The system SHALL show a preview of email templates in the settings page.

#### Scenario: Preview with sample data
- **WHEN** an admin views the email template settings
- **THEN** a preview of each template is shown with sample variable values
