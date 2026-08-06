## MODIFIED Requirements

### Requirement: Edit scheduled email
The system SHALL allow users to edit scheduled emails before they are sent.

#### Scenario: Edit subject and body
- **WHEN** a user opens the edit modal for a scheduled email
- **THEN** they can modify the subject and body fields

#### Scenario: Edit schedule time
- **WHEN** a user edits a scheduled email
- **THEN** they can change the scheduled date and time

#### Scenario: Edit does not change recipient
- **WHEN** a user edits a scheduled email
- **THEN** the recipient field is not editable

#### Scenario: Edited email sends at new time
- **WHEN** a user saves edits to a scheduled email
- **THEN** the Oban job is rescheduled for the updated time
- **AND** the thread message preview updates to reflect new content

#### Scenario: Save with minute-only time input
- **WHEN** a user saves an edited scheduled email with a time entered as `HH:MM` (no seconds)
- **THEN** the email is saved without error
- **AND** the scheduled time is interpreted as `HH:MM:00`
- **AND** the Oban job is rescheduled for that time

#### Scenario: Invalid time does not crash
- **WHEN** a user saves an edited scheduled email with a malformed time value
- **THEN** a validation error is shown
- **AND** the page does not crash or disconnect
