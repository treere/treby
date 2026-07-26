# Candidate Management

## Purpose

Manage candidate profiles within a multi-tenant recruiting system.

## Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin
- **THEN** a new candidate is created for the tenant

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)

### Requirement: List candidates
The system SHALL display all candidates for the current tenant.

#### Scenario: Candidate listing page
- **WHEN** a user navigates to the candidates page
- **THEN** all candidates for their tenant are displayed with name, email, and application count

### Requirement: View candidate profile
The system SHALL display detailed candidate information.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style

### Requirement: Search and filter candidates
The system SHALL allow searching and filtering candidates.

#### Scenario: Search candidates by name or email
- **WHEN** a user types in the search input on the candidates page
- **THEN** candidates whose name or email contains the search term (case-insensitive) are displayed

#### Scenario: Filter candidates by job
- **WHEN** a user selects a job from the filter dropdown
- **THEN** only candidates with an application for that job are shown

#### Scenario: Filter candidates by stage
- **WHEN** a user selects a pipeline stage from the filter dropdown
- **THEN** only candidates with an application in that stage are shown

#### Scenario: Combined search and filters
- **WHEN** a user applies search text and filters simultaneously
- **THEN** only candidates matching ALL criteria are shown

### Requirement: Edit candidate profile
The system SHALL allow editing candidate information from the candidate profile page.

#### Scenario: Inline edit on candidate profile
- **WHEN** a user clicks "Edit" on the candidate profile page
- **THEN** an inline form appears with name, email, phone, LinkedIn URL, and custom fields pre-populated

#### Scenario: Save candidate edit
- **WHEN** a user submits the edit form with valid data
- **THEN** the candidate record is updated and an activity log entry is created

#### Scenario: Candidate edit validation
- **WHEN** a user submits invalid data (missing required fields, duplicate email)
- **THEN** validation errors are shown and the form remains open

### Requirement: Candidate custom fields
The system SHALL support custom fields on candidates.

#### Scenario: Candidate with custom fields
- **WHEN** custom fields are defined for candidates
- **THEN** they appear on the candidate profile and application form
