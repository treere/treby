# Candidate Management

## Purpose

Manage candidate profiles within a multi-tenant recruiting system.

## Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant. The system SHALL not return or list candidates that have been absorbed into another candidate by a merge.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin
- **THEN** a new candidate is created for the tenant

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)
- **AND** the existing candidate is an active (non-absorbed) candidate

#### Scenario: Absorbed candidate is not reused
- **WHEN** a user creates a candidate whose email matches an absorbed (merged) candidate
- **THEN** the system creates a new candidate
- **AND** the absorbed candidate remains absorbed

### Requirement: List candidates
The system SHALL display all candidates for the current tenant.

#### Scenario: Candidate listing page
- **WHEN** a user navigates to the candidates page
- **THEN** all candidates for their tenant are displayed with name, email, and application count

### Requirement: View candidate profile
The system SHALL display detailed candidate information, using the candidate's master anagrafica. The system SHALL redirect absorbed candidate profiles to their primary and SHALL show the master anagrafica on the profile.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style

#### Scenario: Absorbed profile redirects
- **WHEN** a user navigates to an absorbed candidate's profile URL
- **THEN** they are redirected to the primary candidate's profile
- **AND** a notice explains the profile was merged

#### Scenario: Profile shows master anagrafica
- **WHEN** a user views a candidate profile
- **THEN** the displayed contact information is the master anagrafica
- **AND** each application additionally shows the anagrafica submitted with that application when it differs from the master

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

### Requirement: Reject candidate from profile
The system SHALL allow rejecting a candidate from the candidate profile page by moving their application to the stage with `stage_type = "rejected"` in the application's effective pipeline.

#### Scenario: Reject candidate with application
- **WHEN** a user clicks "Reject" on a candidate profile with at least one application and confirms with a motivation
- **THEN** the application is moved to the stage with `stage_type = "rejected"` in the application's effective pipeline
- **AND** a rejection conversation message is created

#### Scenario: Reject candidate without application
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** the system displays an error message explaining the candidate has no application to reject

### Requirement: Profile portal actions without applications
The system SHALL allow using the candidate profile's portal actions (send message, request info, reject) for candidates with no applications without crashing the page.

#### Scenario: Request info for candidate without applications
- **WHEN** a user clicks "Request Info" and confirms on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application
- **AND** no conversation is created

#### Scenario: Reject candidate without applications
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application

#### Scenario: New message for candidate without applications
- **WHEN** a user sends a new portal message to a candidate with no applications
- **THEN** the message is created without an application reference
- **AND** no error is raised
