## MODIFIED Requirements

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
