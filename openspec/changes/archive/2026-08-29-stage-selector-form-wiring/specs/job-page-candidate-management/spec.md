# job-page-candidate-management Delta

## MODIFIED Requirements

### Requirement: Inline stage change
The system SHALL allow changing a candidate's stage directly from the job page using a per-card stage selector. The selector SHALL be wired through a form so the change is dispatched without client-side errors.

#### Scenario: Move candidate to another stage
- **WHEN** a user selects a different stage in a candidate card's selector
- **THEN** the application is moved to the selected stage
- **AND** the card appears in the new stage's column

#### Scenario: Selector wired through a form
- **WHEN** a user opens the job detail page
- **THEN** each candidate card's stage selector is inside a form element
- **AND** no "form events require the input to be inside a form" error is raised in the browser console when changing the stage

#### Scenario: Move requires advancer for interview stages
- **WHEN** a user who is not an advancer for an interview stage attempts to move a candidate
- **THEN** the move is prevented
- **AND** the selector is disabled for that stage

#### Scenario: Single-stage pipeline
- **WHEN** the job's effective pipeline has a single stage
- **THEN** the stage selector is disabled

#### Scenario: Real-time update on Kanban
- **WHEN** a user moves a candidate from the job page
- **THEN** the Kanban board for that job reflects the change for all connected users