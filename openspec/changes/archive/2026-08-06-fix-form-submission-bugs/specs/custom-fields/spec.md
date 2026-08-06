## MODIFIED Requirements

### Requirement: Define custom fields
The system SHALL allow admins to define custom fields for candidates, jobs, and applications.

#### Scenario: Create custom field
- **WHEN** an admin creates a custom field with name, type, and target
- **THEN** the field definition is saved in the custom_fields table
- **AND** the form closes and a success message is shown

#### Scenario: Field types
- **WHEN** an admin creates a custom field
- **THEN** they can choose from: text, number, date, select, url

#### Scenario: Select field options
- **WHEN** an admin chooses the "select" type in the custom field form
- **THEN** the options textarea is shown immediately without a page reload
- **AND** the options entered are preserved while editing the rest of the form

#### Scenario: Saving a select field
- **WHEN** an admin saves a "select" custom field with options
- **THEN** each option line is stored as a selectable option on the field
