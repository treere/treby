# Custom Fields

## Purpose

Support dynamic custom fields for candidates, jobs, and applications with type-safe storage and validation.

## Requirements

### Requirement: Define custom fields
The system SHALL allow admins to define custom fields for candidates, jobs, and applications.

#### Scenario: Create custom field
- **WHEN** an admin creates a custom field with name, type, and target
- **THEN** the field definition is saved in the custom_fields table

#### Scenario: Field types
- **WHEN** an admin creates a custom field
- **THEN** they can choose from: text, number, date, select, url

#### Scenario: Select field options
- **WHEN** an admin creates a "select" type field
- **THEN** they can define the available options

### Requirement: Custom field rendering
The system SHALL render custom fields in relevant forms and profiles.

#### Scenario: Application form with custom fields
- **WHEN** a candidate views the application form
- **THEN** custom fields marked as "required for applications" are displayed

#### Scenario: Candidate profile with custom fields
- **WHEN** an authenticated user views a candidate profile
- **THEN** all custom fields for candidates are displayed

### Requirement: Custom field storage
The system SHALL store custom field values in JSONB columns.

#### Scenario: Save custom field value
- **WHEN** a form with custom fields is submitted
- **THEN** the values are stored in the target table's custom_fields JSONB column

#### Scenario: Query custom fields
- **WHEN** an admin queries candidates by custom field value
- **THEN** PostgreSQL JSONB operators are used for efficient querying

### Requirement: Custom field validation
The system SHALL validate custom field values based on field type.

#### Scenario: Required field
- **WHEN** a custom field is marked as required
- **THEN** the form cannot be submitted without a value for that field

#### Scenario: URL field validation
- **WHEN** a custom field has type "url"
- **THEN** the value must be a valid URL format
