# Email Notifications

## Purpose

Automated notification system that sends emails on pipeline stage transitions, new applications, and application confirmations, with per-tenant configurable preferences.

## Requirements

### Requirement: Stage change candidate notification
The system SHALL send an email to the candidate when their application is moved to a pipeline stage that has a configured email template. When the candidate portal is enabled for the tenant, the email SHALL be a short notification (ping) linking to the portal message, not a full-content email.

#### Scenario: Stage has email template
- **WHEN** a user moves a candidate to a pipeline stage with a configured email template
- **AND** the `stage_change_candidate` notification is enabled for the tenant
- **THEN** the candidate receives an email with the template content rendered with their variables

#### Scenario: Stage change with portal enabled
- **WHEN** a user moves a candidate to a pipeline stage
- **AND** the candidate has an active portal conversation for that application
- **THEN** a system message is created in the conversation with the stage change info
- **AND** the notification email (if sent) is a short ping: "Your application for {job_title} has moved to {stage_name}" with a "View in Portal" button linking to the conversation

#### Scenario: Stage has no email template
- **WHEN** a user moves a candidate to a pipeline stage with no configured email template
- **THEN** no email is sent and the stage move completes normally

#### Scenario: Notification disabled
- **WHEN** the `stage_change_candidate` notification is disabled for the tenant
- **AND** a user moves a candidate to a stage with a configured email template
- **THEN** no email is sent and the stage move completes normally

#### Scenario: Email delivery failure
- **WHEN** email delivery fails during a stage change notification
- **THEN** the stage move completes successfully
- **AND** the failure is logged in the activity audit trail with error details

### Requirement: New application candidate confirmation
The system SHALL send a confirmation email to the candidate after they successfully submit an application via the public career page. When the candidate portal is enabled, the email SHALL be a short notification linking to the portal.

#### Scenario: Successful application submission
- **WHEN** a candidate submits a valid application on the career page
- **AND** the `new_application_candidate` notification is enabled for the tenant
- **THEN** the candidate receives a confirmation email thanking them for applying

#### Scenario: Confirmation with portal
- **WHEN** a candidate submits a valid application
- **AND** the tenant has the candidate portal enabled
- **THEN** the confirmation email contains: a brief "Thank you for applying" message and a prominent "View Your Application" button linking to `/:tenant_slug/portal`
- **AND** a welcome conversation is created in the portal with a system message

#### Scenario: Confirmation email content
- **WHEN** a confirmation email is sent to a candidate
- **THEN** the email includes: candidate name, job title, company name, and a link back to the career page

#### Scenario: Notification disabled
- **WHEN** the `new_application_candidate` notification is disabled for the tenant
- **AND** a candidate submits an application
- **THEN** no confirmation email is sent

#### Scenario: Application via manual creation
- **WHEN** an authenticated user manually creates an application for a candidate
- **THEN** no confirmation email is sent (only public career page submissions trigger confirmations)

### Requirement: New application team alert
The system SHALL send a notification email to the job owner and tenant admins when a new application is submitted for any job.

#### Scenario: New application alert
- **WHEN** a new application is created (via career page or manual creation)
- **AND** the `new_application_team` notification is enabled for the tenant
- **THEN** all tenant admins and the job's assigned owner receive an email alert

#### Scenario: Alert email content
- **WHEN** a team alert email is sent
- **THEN** the email includes: candidate name, job title, application source, and a link to the application in the pipeline

#### Scenario: No job owner assigned
- **WHEN** a job has no assigned owner
- **AND** a new application is submitted
- **THEN** only tenant admins receive the team alert

#### Scenario: Notification disabled
- **WHEN** the `new_application_team` notification is disabled for the tenant
- **THEN** no team alert emails are sent

### Requirement: Notification preferences
The system SHALL allow tenant admins to configure which notification types are enabled or disabled.

#### Scenario: Default preferences
- **WHEN** a new tenant is created
- **THEN** all notification types default to enabled

#### Scenario: Toggle notification type
- **WHEN** an admin navigates to Settings > Notifications
- **THEN** they see a list of notification types with toggle switches
- **AND** they can enable or disable each type independently

#### Scenario: Preferences persisted
- **WHEN** an admin saves notification preferences
- **THEN** the settings are persisted in the tenant's settings JSON
- **AND** future notifications respect the updated preferences

### Requirement: Email activity logging
The system SHALL log all notification emails in the activity audit trail.

#### Scenario: Successful email logged
- **WHEN** a notification email is sent successfully
- **THEN** an activity event is logged with: email type, recipient, subject, and status "sent"

#### Scenario: Failed email logged
- **WHEN** a notification email fails to send
- **THEN** an activity event is logged with: email type, recipient, status "failed", and error details
