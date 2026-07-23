# Candidate Search & Filtering

## Purpose

Allow hiring managers to quickly find candidates by name, email, job, or stage when the candidate list grows beyond a handful.

## Requirements

### Requirement: Search candidates
The system SHALL allow searching candidates by name or email.

#### Scenario: Text search
- **WHEN** a user types in the search input on the candidates page
- **THEN** candidates whose name or email contains the search term are shown (case-insensitive)

#### Scenario: Empty search
- **WHEN** the search input is cleared
- **THEN** all candidates for the tenant are shown

### Requirement: Filter by job
The system SHALL allow filtering candidates by the job they applied to.

#### Scenario: Job filter
- **WHEN** a user selects a specific job from the filter dropdown
- **THEN** only candidates who have an application for that job are shown

#### Scenario: "All jobs" filter
- **WHEN** "All jobs" is selected
- **THEN** all candidates for the tenant are shown regardless of job

### Requirement: Filter by pipeline stage
The system SHALL allow filtering candidates by their current pipeline stage.

#### Scenario: Stage filter
- **WHEN** a user selects a specific stage from the filter dropdown
- **THEN** only candidates who have an application in that stage are shown

#### Scenario: "All stages" filter
- **WHEN** "All stages" is selected
- **THEN** all candidates are shown regardless of stage

### Requirement: Combined filters
The system SHALL support combining search, job filter, and stage filter simultaneously.

#### Scenario: All filters applied
- **WHEN** a user applies search text, job filter, and stage filter
- **THEN** only candidates matching ALL criteria are shown
