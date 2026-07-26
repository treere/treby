# CSV Import

## Purpose

Allow hiring managers to bring existing candidate data from spreadsheets into Treby, eliminating the manual entry barrier when switching from another tool.

## Requirements

### Requirement: Upload CSV file
The system SHALL accept CSV file uploads for candidate import.

#### Scenario: Upload CSV
- **WHEN** a user selects a CSV file on the import page
- **THEN** the file is uploaded and validated (correct format, under 10MB)

#### Scenario: Invalid file format
- **WHEN** a user uploads a non-CSV file
- **THEN** an error message is shown: "Please upload a CSV file"

#### Scenario: File too large
- **WHEN** a user uploads a CSV file larger than 10MB
- **THEN** an error message is shown: "File must be under 10MB"

### Requirement: Map CSV columns to fields
The system SHALL allow users to map CSV columns to candidate and application fields.

#### Scenario: Auto-detect column mapping
- **WHEN** a CSV is uploaded with header rows
- **THEN** the system auto-maps columns by matching header names to field names (case-insensitive)

#### Scenario: Manual column mapping
- **WHEN** auto-detection is incorrect or incomplete
- **THEN** the user can override the mapping by selecting a field for each CSV column

#### Scenario: Available mapping targets
- **WHEN** the user is mapping columns
- **THEN** available fields include: name, email, phone, linkedin_url, job (title or ID), and all custom fields defined for candidates and applications

#### Scenario: Unmapped columns
- **WHEN** a CSV column is not mapped to any field
- **THEN** the column is skipped during import

### Requirement: Preview before import
The system SHALL show a preview of the import before committing.

#### Scenario: Preview table
- **WHEN** the user has mapped columns and clicks "Preview"
- **THEN** a table shows the first 10 rows with mapped field values

#### Scenario: Duplicate detection in preview
- **WHEN** a candidate email in the CSV matches an existing candidate in the tenant
- **THEN** the row is highlighted and marked as "Duplicate — will be skipped"

#### Scenario: Validation errors in preview
- **WHEN** a row has missing required fields (e.g., no email)
- **THEN** the row is highlighted and marked with the specific error

### Requirement: Import candidates
The system SHALL import candidates from the mapped CSV.

#### Scenario: Successful import
- **WHEN** the user confirms the import
- **THEN** all valid rows are imported as candidates and applications
- **AND** a summary is shown: "X imported, Y duplicates skipped, Z errors"

#### Scenario: Import with job assignment
- **WHEN** the user selects a target job and pipeline stage during import
- **THEN** each imported candidate gets an application for that job in the specified stage

#### Scenario: Import without job assignment
- **WHEN** no target job is selected
- **THEN** candidates are created without applications

#### Scenario: Import with source
- **WHEN** the user selects a source during import
- **THEN** all imported applications are tagged with that source

#### Scenario: Deduplication by email
- **WHEN** a CSV row has an email that matches an existing candidate in the tenant
- **THEN** the candidate is NOT created again
- **AND** the row is counted as a duplicate

#### Scenario: Import in single transaction
- **WHEN** the import encounters an error mid-way
- **THEN** no partial data is committed — the entire import is rolled back
- **AND** an error message is shown

### Requirement: Import history
The system SHALL show a history of previous imports.

#### Scenario: Import log
- **WHEN** a user navigates to the import page
- **THEN** previous imports are listed with date, file name, and summary (imported/skipped/errors)
