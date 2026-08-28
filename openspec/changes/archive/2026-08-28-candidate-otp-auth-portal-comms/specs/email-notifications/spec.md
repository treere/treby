## MODIFIED Requirements

### Requirement: Stage change candidate notification
The system SHALL notify the candidate of pipeline stage changes through a portal conversation message. When the candidate's email notification preferences allow it, the system SHALL send a short ping email linking to the portal — never a full-content email.

#### Scenario: Stage change creates portal message
- **WHEN** a user moves a candidate to a new pipeline stage
- **THEN** a system message is created in the candidate's conversation for that application with the stage change info
- **AND** if the stage has a configured message template, the template content is used as the message body

#### Scenario: Stage change with ping email
- **WHEN** a user moves a candidate to a new pipeline stage
- **AND** the `stage_change_candidate` notification is enabled for the tenant
- **AND** the candidate has the `status_change` preference enabled
- **THEN** the candidate receives a short ping email: "Your application for {job_title} has moved to {stage_name}"
- **AND** the email contains a "View in Portal" button linking to `/:tenant_slug/portal`

#### Scenario: No ping email when disabled
- **WHEN** the `stage_change_candidate` notification is disabled for the tenant
- **OR** the candidate has the `status_change` preference disabled
- **THEN** no ping email is sent and the stage move completes normally

#### Scenario: Email delivery failure
- **WHEN** email delivery fails during a stage change notification
- **THEN** the stage move completes successfully
- **AND** the failure is logged in the activity audit trail with error details

### Requirement: New application candidate confirmation
The system SHALL send a confirmation notification to the candidate after they successfully submit an application via the public career page. The confirmation SHALL be a short ping email linking to the portal, never a full-content email.

#### Scenario: Successful application submission
- **WHEN** a candidate submits a valid application on the career page
- **THEN** a welcome conversation is created in the portal with a system message
- **AND** if the `new_application_candidate` notification is enabled for the tenant, the candidate receives a short confirmation ping email

#### Scenario: Confirmation ping content
- **WHEN** a confirmation ping email is sent to a candidate
- **THEN** the email contains a brief "Thank you for applying" message
- **AND** a prominent "View Your Application" button linking to `/:tenant_slug/portal`

#### Scenario: Notification disabled
- **WHEN** the `new_application_candidate` notification is disabled for the tenant
- **AND** a candidate submits an application
- **THEN** no confirmation email is sent

#### Scenario: Application via manual creation
- **WHEN** an authenticated user manually creates an application for a candidate
- **THEN** no confirmation email is sent (only public career page submissions trigger confirmations)

## REMOVED Requirements

### Requirement: New application team alert
**Reason**: Team alerts move in-app; recruiters and admins are notified through the in-app activity log instead of email.
**Migration**: New applications are logged as tenant-scoped activity events surfaced in the app UI (dashboard/team feed); no email is sent to admins or job owners.