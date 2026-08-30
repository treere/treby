## MODIFIED Requirements

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages. For interview-type stages, advancement is restricted to assigned advancers and requires all examiners to have submitted scorecards. For offer-type stages, the Advance action SHALL be available when the current state is not blocked.

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

#### Scenario: Advance from offer stage when not blocked
- **WHEN** a candidate is in an offer-type stage
- **AND** `Pipeline.current_state` reports `blocked?: false`
- **THEN** the card shows an enabled `Advance` button
- **AND** clicking `Advance` moves the candidate to the next stage (Hired)

#### Scenario: Offer stage blocked shows disabled Advance
- **WHEN** a candidate is in an offer-type stage and blocked
- **THEN** the card shows `Advance` disabled with tooltip explaining blockers
