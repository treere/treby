## MODIFIED Requirements

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages. For interview-type stages, advancement is restricted to assigned advancers and requires all examiners to have submitted scorecards. The board SHALL surface advancer information and allowed targets.

#### Scenario: Move candidate to new stage
- **WHEN** a user drags a candidate card from one stage column to another
- **THEN** the candidate's application is updated to the new stage
- **AND** the change is reflected in real-time for all connected users

#### Scenario: Advancer visibility
- **WHEN** a user views the pipeline board
- **THEN** each stage header shows its advancers

#### Scenario: Move affordance with allowed targets
- **WHEN** a user views a candidate card
- **THEN** a Move dropdown shows only stages the user is allowed to move to
