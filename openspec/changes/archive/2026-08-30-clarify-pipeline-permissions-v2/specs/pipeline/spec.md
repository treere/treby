## MODIFIED Requirements

### Requirement: Drag-and-drop stage transition

The system SHALL allow dragging candidate cards between stages and SHALL indicate when the user lacks advancer permission before drag.

#### Scenario: Only advancers can advance from stage

- **WHEN** a user who is not an advancer for the current stage attempts to advance a candidate
- **THEN** the system prevents the action with a permission error

#### Scenario: Advancer permission visible before drag

- **WHEN** a user views the pipeline board and is not an advancer for a stage (and not admin)
- **THEN** the stage column shows a tooltip `Only stage advancers can move` and drag is visually disabled
