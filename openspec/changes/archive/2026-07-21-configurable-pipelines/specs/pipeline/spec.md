## MODIFIED Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages from the job's assigned pipeline.

#### Scenario: Pipeline board loads
- **WHEN** a user navigates to the pipeline for a specific job
- **THEN** a Kanban board is displayed with columns for each stage in the job's assigned pipeline
- **AND** if the job has no explicit pipeline, the tenant's default pipeline is used

#### Scenario: Candidates shown in columns
- **WHEN** the pipeline board loads
- **THEN** each candidate card appears in the column matching their current stage

#### Scenario: Interview stage indicator
- **WHEN** a candidate card is in a stage with type "interview"
- **THEN** the card shows a camera icon indicating an interview is scheduled
- **AND** if an interview is scheduled, the card shows the interview date/time

### Requirement: Pipeline stages management
The system SHALL allow admins to customize pipeline stages within a specific pipeline.

#### Scenario: Add new stage
- **WHEN** an admin adds a new pipeline stage to a pipeline
- **THEN** the stage appears on the Kanban board for jobs using that pipeline

#### Scenario: Remove stage
- **WHEN** an admin removes a pipeline stage with no candidates
- **THEN** the stage is deleted from the pipeline

#### Scenario: Remove stage with candidates
- **WHEN** an admin removes a stage with candidates
- **THEN** a reassignment modal is displayed listing other stages in the pipeline
- **AND** the admin selects a destination stage for the candidates
- **AND** all candidates are moved to the selected stage
- **AND** the original stage is deleted
