## MODIFIED Requirements

### Requirement: Job creation and editing
The system SHALL allow creating and updating jobs with structured optional fields including location and employment details.

#### Scenario: Create job with structured fields
- **WHEN** a team member creates a job with `location`, `employment_type`, and `workplace_type`
- **THEN** the job is persisted with those values
- **AND** invalid enum values are rejected with a validation error

#### Scenario: Create job without structured fields
- **WHEN** a team member creates a job providing only `title` and `description`
- **THEN** the job is created successfully with structured fields defaulting to `nil`

#### Scenario: Edit job structured fields
- **WHEN** a team member updates `location` or type fields on an existing job
- **THEN** the changes are persisted and visible on the next load
