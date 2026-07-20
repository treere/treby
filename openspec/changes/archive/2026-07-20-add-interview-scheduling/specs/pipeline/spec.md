## MODIFIED Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages.

#### Scenario: Pipeline board loads
- **WHEN** a user navigates to the pipeline for a specific job
- **THEN** a Kanban board is displayed with columns for each pipeline stage

#### Scenario: Candidates shown in columns
- **WHEN** the pipeline board loads
- **THEN** each candidate card appears in the column matching their current stage

#### Scenario: Interview stage indicator
- **WHEN** a candidate card is in the "Interview" stage
- **THEN** the card shows a camera icon indicating an interview is scheduled
- **AND** if an interview is scheduled, the card shows the interview date/time

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages.

#### Scenario: Move candidate to new stage
- **WHEN** a user drags a candidate card from one stage column to another
- **THEN** the candidate's application is updated to the new stage
- **AND** the change is reflected in real-time for all connected users

#### Scenario: Drop in same stage
- **WHEN** a user drops a card in the same stage column
- **THEN** no change is made
