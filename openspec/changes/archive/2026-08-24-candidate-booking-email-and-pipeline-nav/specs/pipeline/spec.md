# Pipeline

## Delta

### ADDED Requirements

### Requirement: Candidate cards link to candidate details
The system SHALL allow users to navigate from a pipeline candidate card to the candidate's detail page.

#### Scenario: Click candidate card opens details
- **WHEN** a user clicks a candidate card in the pipeline board
- **THEN** the system navigates to `/app/candidates/:candidate_id`
- **AND** displays the candidate's details, applications, interviews, notes, and activity

#### Scenario: Drag-and-drop remains functional
- **WHEN** a user drags a candidate card between stages
- **THEN** the click navigation does not interfere with the drag-and-drop interaction

### MODIFIED Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages from the job's assigned pipeline, accessible only from the job's pages.

#### Scenario: Pipeline board loads
- **WHEN** a user navigates to the pipeline for a specific job from the Jobs page
- **THEN** a Kanban board is displayed with columns for each stage in the job's assigned pipeline
- **AND** if the job has no explicit pipeline, the tenant's default pipeline is used

#### Scenario: Standalone pipeline page removed
- **WHEN** a user opens the top-level Pipeline URL
- **THEN** there is no top-level `/app/pipeline` landing page
- **AND** the pipeline is only reachable per job (e.g. `/app/pipeline/:job_id`)

#### Scenario: Candidates shown in columns
- **WHEN** the pipeline board loads
- **THEN** each candidate card appears in the column matching their current stage

#### Scenario: Interview stage indicator
- **WHEN** a candidate card is in a stage with type "interview"
- **THEN** the card shows a camera icon indicating an interview is scheduled
- **AND** if an interview is scheduled, the card shows the interview date/time
