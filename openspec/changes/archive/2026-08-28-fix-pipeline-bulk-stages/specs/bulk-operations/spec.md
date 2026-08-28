# Bulk Operations

## Delta

## MODIFIED Requirements

### Requirement: Bulk move to stage
The system SHALL allow moving multiple selected applications to a specific pipeline stage. The stages offered SHALL come from the job's effective pipeline (explicit pipeline if assigned, otherwise the tenant's default pipeline).

#### Scenario: Bulk move via action bar
- **WHEN** a user selects applications and clicks "Move to Stage"
- **THEN** a dropdown shows available stages in the pipeline
- **AND** selecting a stage and confirming moves all selected applications

#### Scenario: Bulk move stage list uses effective pipeline
- **WHEN** a user opens the bulk action bar on a pipeline board for a job
- **THEN** the dropdown lists the stages of the job's effective pipeline, including a job with no explicit pipeline (falling back to the tenant's default pipeline)

#### Scenario: Bulk move with no stages available
- **WHEN** the effective pipeline has no stages
- **THEN** the "Move to Stage" action is disabled instead of showing an empty dropdown

#### Scenario: Bulk move with message templates
- **WHEN** the target stage has a message template configured
- **THEN** a confirmation dialog shows "Send message to all X candidates?" with Send/Skip options

#### Scenario: Bulk move in single transaction
- **WHEN** a bulk move is executed
- **THEN** all moves happen in a single database transaction
- **AND** if any move fails, all moves are rolled back