# Candidate Management (Modified)

## Changes from Main Spec

### Added: Search and filter candidates

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

### Added: Edit candidate profile

#### Scenario: Inline edit on candidate profile
- **WHEN** a user clicks "Edit" on the candidate profile page
- **THEN** an inline form appears with name, email, phone, LinkedIn URL, and custom fields pre-populated

#### Scenario: Save candidate edit
- **WHEN** a user submits the edit form with valid data
- **THEN** the candidate record is updated and an activity log entry is created

#### Scenario: Candidate edit validation
- **WHEN** a user submits invalid data (missing required fields, duplicate email)
- **THEN** validation errors are shown and the form remains open
