# Pipeline (delta)

## MODIFIED Requirements

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages. For interview-type stages, advancement is restricted to assigned advancers and requires all examiners to have submitted scorecards.

#### Scenario: Move candidate to new stage
- **WHEN** a user drags a candidate card from one stage column to another
- **THEN** the candidate's application is updated to the new stage
- **AND** the change is reflected in real-time for all connected users

#### Scenario: Drop in same stage
- **WHEN** a user drops a card in the same stage column
- **THEN** no change is made

#### Scenario: Advance from interview stage requires scorecards
- **WHEN** a user attempts to advance a candidate from an interview-type stage
- **AND** not all examiners for that stage have submitted their scorecards
- **THEN** the system prevents the advancement
- **AND** displays a message indicating which examiners still need to submit feedback

#### Scenario: Advance from interview stage with all scorecards
- **WHEN** a user attempts to advance a candidate from an interview-type stage
- **AND** all examiners have submitted their scorecards
- **THEN** the advancement proceeds normally

#### Scenario: Only advancers can advance from stage
- **WHEN** a user who is not an advancer for the current stage attempts to advance a candidate
- **THEN** the system prevents the action with a permission error

### Requirement: Pipeline stages management
The system SHALL allow admins to customize pipeline stages.

#### Scenario: Add new stage
- **WHEN** an admin adds a new pipeline stage
- **THEN** the stage appears on the Kanban board

#### Scenario: Remove stage
- **WHEN** an admin removes a pipeline stage with no candidates
- **THEN** the stage is deleted from the board

#### Scenario: Remove stage with candidates
- **WHEN** an admin removes a stage with candidates
- **THEN** a reassignment modal is displayed listing other stages in the pipeline
- **AND** the admin selects a destination stage for the candidates
- **AND** all candidates are moved to the selected stage
- **AND** the original stage is deleted

## ADDED Requirements

### Requirement: Advance or reject candidate from stage
The system SHALL allow assigned advancers to manually advance or reject candidates from a stage.

#### Scenario: Advance candidate
- **WHEN** an advancer clicks "Advance" on a candidate in their stage
- **THEN** the candidate moves to the next stage in the pipeline

#### Scenario: Reject candidate with motivation
- **WHEN** an advancer clicks "Reject" on a candidate in their stage
- **THEN** the system prompts for a rejection motivation
- **AND** upon confirmation, the candidate is marked as rejected with the motivation
- **AND** the candidate is removed from the active pipeline

#### Scenario: Reject requires motivation
- **WHEN** an advancer attempts to reject a candidate without providing a motivation
- **THEN** the system prevents the rejection and prompts for a motivation
