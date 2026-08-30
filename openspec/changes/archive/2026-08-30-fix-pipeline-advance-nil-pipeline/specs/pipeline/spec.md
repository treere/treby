## MODIFIED Requirements

### Requirement: Advance or reject candidate from stage
The system SHALL allow assigned advancers to manually advance or reject candidates from a stage. Rejection SHALL target the stage with `stage_type = "rejected"` in the job's effective pipeline, resolved even when the job has no explicit pipeline. Advancement SHALL resolve the job's effective pipeline (explicit or default) so that jobs without an explicit pipeline do not crash.

#### Scenario: Advance candidate
- **WHEN** an advancer clicks "Advance" on a candidate in their stage
- **THEN** the candidate moves to the next stage in the pipeline

#### Scenario: Advance candidate in default-pipeline job
- **WHEN** an advancer clicks "Advance" on a candidate in a job that has no explicit pipeline
- **THEN** the system resolves the tenant's default pipeline stages
- **AND** the candidate moves to the next stage in that pipeline

#### Scenario: Reject candidate with motivation
- **WHEN** an advancer clicks "Reject" on a candidate in their stage
- **THEN** the system prompts for a rejection motivation
- **AND** upon confirmation, the candidate is marked as rejected with the motivation
- **AND** the candidate is removed from the active pipeline

#### Scenario: Reject candidate in default-pipeline job
- **WHEN** an advancer rejects a candidate in a job that has no explicit pipeline
- **THEN** the system resolves the tenant's default pipeline stages
- **AND** the candidate is moved to the stage with `stage_type = "rejected"` and removed from the active pipeline

#### Scenario: Reject requires motivation
- **WHEN** an advancer attempts to reject a candidate without providing a motivation
- **THEN** the system prevents the rejection and prompts for a motivation

#### Scenario: Reject when pipeline has no rejected stage
- **WHEN** the effective pipeline has no stage with `stage_type = "rejected"`
- **THEN** the reject action is disabled with a message explaining a rejected stage is required
