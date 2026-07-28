## ADDED Requirements

### Requirement: Form submissions show flash on validation failure
When a form submission fails due to changeset validation errors, the system SHALL display a flash error message in addition to re-rendering the form with inline field errors.

#### Scenario: Job creation with missing required fields
- **WHEN** a user submits the create job form with an empty title
- **THEN** a flash message "Please review the errors below" is displayed
- **AND** the form re-renders with inline validation errors on the affected fields

#### Scenario: Candidate creation with invalid email
- **WHEN** a user submits the create candidate form with an email missing "@"
- **THEN** a flash message "Please review the errors below" is displayed
- **AND** the form re-renders with inline validation errors on the email field

#### Scenario: Settings form submission with validation errors
- **WHEN** a user submits any settings form (pipeline, branding, fields, sources, availability, email templates, pipeline stages, language) with invalid data
- **THEN** a flash message "Please review the errors below" is displayed
- **AND** the form re-renders with inline validation errors

#### Scenario: Candidate note creation with empty content
- **WHEN** a user submits the create note form with empty content
- **THEN** a flash message "Please review the errors below" is displayed
- **AND** the note form re-renders with inline validation errors

#### Scenario: Candidate inline edit with validation errors
- **WHEN** a user submits an inline edit form for a candidate with invalid data
- **THEN** a flash message "Please review the errors below" is displayed
- **AND** the edit form re-renders with inline validation errors

### Requirement: Public application page handles errors gracefully
The public candidate application page SHALL handle candidate creation and application submission failures without crashing, displaying user-friendly error messages instead.

#### Scenario: Applicant submits with invalid email
- **WHEN** a public applicant submits the application form with an email address missing "@"
- **THEN** the page does not crash
- **AND** a flash message is displayed explaining the submission failed
- **AND** the form remains visible for the applicant to correct their input

#### Scenario: Application creation fails
- **WHEN** a public applicant's candidate creation succeeds but application creation fails
- **THEN** a flash message "Failed to submit application" is displayed
- **AND** the form remains visible for the applicant to retry

### Requirement: Pipeline toggle review shows feedback on failure
The pipeline board SHALL display a flash error message when toggling a candidate's review status fails, instead of silently swallowing the error.

#### Scenario: Toggle review status fails
- **WHEN** a user clicks the review toggle on a pipeline card and the operation fails
- **THEN** a flash message "Failed to update review status" is displayed
- **AND** the pipeline board remains in its previous state

### Requirement: Consistent error flash pattern
All form submission error handlers SHALL use the same flash message text for consistency.

#### Scenario: All changeset failures use the same message
- **WHEN** any form submission fails with changeset validation errors across the application
- **THEN** the flash error message is "Please review the errors below" in all cases
