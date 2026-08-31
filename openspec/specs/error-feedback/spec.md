## Purpose

Ensure users receive clear, consistent feedback when form submissions or actions fail due to validation errors, improving usability and reducing confusion across the application.

## Requirements

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
All form submission error handlers SHALL use the same flash message text for consistency. Flash rendering SHALL use the design-system `Feedback.Toast` (or `CoreComponents.flash` that delegates to it) with `kind` `:info`/`:error`/`:success`/`:warning`, and no screen SHALL duplicate flash/toast markup outside the design system.

#### Scenario: All changeset failures use the same message
- **WHEN** any form submission fails with changeset validation errors across the application
- **THEN** the flash error message is "Please review the errors below" in all cases

#### Scenario: Toast styling is centralized
- **WHEN** a flash is rendered (info/error/success/warning)
- **THEN** it uses the design-system toast classes (`alert` / `alert-info` / `alert-error` / etc.) and is reachable via the shared `flash_group` component

#### Scenario: No ad-hoc toast markup outside DS
- **WHEN** CI scans `lib/treby_web` for `class="alert` or `toast` outside `lib/treby_web/components/design_system/feedback.ex` and `core_components.ex` flash delegation
- **THEN** no ad-hoc duplicates are found (storybook Toast story is the reference)

### Requirement: Storybook documents toast/flash variants
The storybook SHALL include a `Feedback.Toast` story showing each `kind` (`info`/`success`/`warning`/`error`), with and without `title`, so error-feedback styling is previewable in isolation.

#### Scenario: Toast story covers all kinds
- **WHEN** a developer opens the Toast/Feedback story
- **THEN** controls allow switching `kind` and toggling `title`, and the preview updates for each kind in both light and dark themes
