# Candidate Editing

## Purpose

Allow hiring managers to fix typos and update candidate information without deleting and recreating.

## Requirements

### Requirement: Edit candidate profile
The system SHALL allow editing candidate information from the candidate profile page.

#### Scenario: Inline edit form
- **WHEN** a user clicks "Edit" on the candidate profile page
- **THEN** an inline edit form appears with fields for name, email, phone, LinkedIn URL, and custom fields
- **AND** the form is pre-populated with current values

#### Scenario: Save changes
- **WHEN** a user submits the edit form with valid data
- **THEN** the candidate record is updated
- **AND** the profile page shows the updated information
- **AND** an activity log entry is created for the update

#### Scenario: Validation errors
- **WHEN** a user submits the edit form with invalid data (missing required fields, duplicate email)
- **THEN** validation errors are displayed inline
- **AND** the form remains open for correction

### Requirement: Edit custom fields
The system SHALL allow editing custom field values on the candidate profile.

#### Scenario: Custom fields in edit form
- **WHEN** a user opens the edit form on the candidate profile
- **THEN** custom fields defined for candidates are shown with current values
- **AND** custom field values are saved along with the candidate update
