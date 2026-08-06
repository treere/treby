## MODIFIED Requirements

### Requirement: Bulk send email
The system SHALL allow sending a custom email to multiple selected candidates, either immediately or scheduled.

#### Scenario: Bulk email composer
- **WHEN** a user selects candidates and clicks "Send Email"
- **THEN** an email composer opens with subject and body fields
- **AND** variables like `{candidate_name}` are interpolated per recipient
- **AND** the composer includes immediate send and schedule options

#### Scenario: Composer fields update without errors
- **WHEN** a user types in the subject, body, date, or time fields of the bulk email composer
- **THEN** each change is sent to the server and reflected in the composer
- **AND** no "form events require the input to be inside a form" error is raised

#### Scenario: Enter in the composer does not reload the page
- **WHEN** a user presses Enter while typing in a bulk email composer text field
- **THEN** the page does not reload or navigate
- **AND** the typed content is preserved

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
