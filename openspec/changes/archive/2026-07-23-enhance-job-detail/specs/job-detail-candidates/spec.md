## ADDED Requirements

### Requirement: Display candidates on job detail page
The system SHALL display all candidates who have applied to a job on the job detail page.

#### Scenario: Job with candidates
- **WHEN** a user views the detail page for a job that has applications
- **THEN** a candidates section is displayed below the job description
- **AND** each candidate shows their name, email, current pipeline stage, and application date

#### Scenario: Job with no candidates
- **WHEN** a user views the detail page for a job that has no applications
- **THEN** the candidates section shows an empty state message (e.g. "No candidates yet")

### Requirement: Pipeline stage badge for candidates
The system SHALL display each candidate's current pipeline stage as a colored badge.

#### Scenario: Candidate in a pipeline stage
- **WHEN** a candidate's application is in a pipeline stage
- **THEN** the stage name is displayed as a badge with the stage's configured color
