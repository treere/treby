## MODIFIED Requirements

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
