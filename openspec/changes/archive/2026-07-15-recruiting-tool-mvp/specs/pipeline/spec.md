## ADDED Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages.

#### Scenario: Pipeline board loads
- **WHEN** a user navigates to the pipeline for a specific job
- **THEN** a Kanban board is displayed with columns for each pipeline stage

#### Scenario: Candidates shown in columns
- **WHEN** the pipeline board loads
- **THEN** each candidate card appears in the column matching their current stage

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages.

#### Scenario: Move candidate to new stage
- **WHEN** a user drags a candidate card from one stage column to another
- **THEN** the candidate's application is updated to the new stage
- **AND** the change is reflected in real-time for all connected users

#### Scenario: Drop in same stage
- **WHEN** a user drops a card in the same stage column
- **THEN** no change is made

### Requirement: Pipeline stages management
The system SHALL allow admins to customize pipeline stages.

#### Scenario: Add new stage
- **WHEN** an admin adds a new pipeline stage
- **THEN** the stage appears on the Kanban board

#### Scenario: Remove stage
- **WHEN** an admin removes a pipeline stage with no candidates
- **THEN** the stage is deleted from the board

#### Scenario: Remove stage with candidates
- **WHEN** an admin tries to remove a stage with candidates
- **THEN** the system prevents deletion with an error message

### Requirement: Real-time updates
The system SHALL broadcast pipeline changes to all connected clients.

#### Scenario: Multi-user real-time sync
- **WHEN** one user moves a candidate to a new stage
- **THEN** all other users viewing the same pipeline see the change immediately
