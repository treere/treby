# Pipeline

## Delta

## MODIFIED Requirements

### Requirement: Bulk move candidates
The system SHALL allow moving multiple selected candidates to a stage simultaneously. The stages offered SHALL be the effective pipeline's stages for the currently viewed job.

#### Scenario: Bulk move via selection
- **WHEN** a user selects multiple candidate cards and chooses "Move to Stage"
- **THEN** a dropdown of available stages is shown
- **AND** confirming moves all selected applications to the chosen stage

#### Scenario: Bulk move dropdown populated per job
- **WHEN** a user opens the bulk action bar on a pipeline board for a job without an explicit pipeline
- **THEN** the dropdown lists the tenant's default pipeline stages for that job

#### Scenario: Bulk move disabled without stages
- **WHEN** the job's effective pipeline has no stages
- **THEN** the "Move to Stage" option is disabled

#### Scenario: Bulk move with email notification
- **WHEN** the target stage has an email template and the user chooses to send
- **THEN** emails are sent to all selected candidates
- **AND** a summary is shown: "X moved, Y emails sent"