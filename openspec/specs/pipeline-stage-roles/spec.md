# Pipeline Stage Roles

## Purpose

Define who can examine (interview), review, and advance candidates at each pipeline stage, with configurable minimum examiner requirements for interview stages.

## Requirements

### Requirement: Assign examiners to pipeline stages
The system SHALL allow admins to assign one or more examiners (users) to each pipeline stage.

#### Scenario: Assign examiner to stage
- **WHEN** an admin assigns a user as an examiner to a pipeline stage
- **THEN** the user is added to the stage's examiner list
- **AND** the user can conduct interviews or provide feedback for candidates in that stage

#### Scenario: Remove examiner from stage
- **WHEN** an admin removes an examiner from a pipeline stage
- **THEN** the user is removed from the stage's examiner list
- **AND** the user can no longer be scheduled for interviews in that stage
- **AND** existing scheduled interviews with that user are NOT cancelled (they complete normally)

#### Scenario: Multiple examiners per stage
- **WHEN** an admin assigns multiple examiners to an interview-type stage
- **THEN** all assigned examiners are eligible to participate in interviews for that stage
- **AND** the candidate self-scheduling page shows slots from all eligible examiners

### Requirement: Assign reviewers to pipeline stages
The system SHALL allow admins to assign one or more reviewers (users) to each pipeline stage.

#### Scenario: Assign reviewer to stage
- **WHEN** an admin assigns a user as a reviewer to a pipeline stage
- **THEN** the user is added to the stage's reviewer list
- **AND** the user can review applications and provide feedback for candidates in that stage

#### Scenario: Remove reviewer from stage
- **WHEN** an admin removes a reviewer from a pipeline stage
- **THEN** the user is removed from the stage's reviewer list

### Requirement: Assign advancers to pipeline stages
The system SHALL allow admins to assign one or more advancers (users) to each pipeline stage. Only assigned advancers may advance or reject candidates from that stage.

#### Scenario: Assign advancer to stage
- **WHEN** an admin assigns a user as an advancer to a pipeline stage
- **THEN** the user can advance or reject candidates from that stage

#### Scenario: Multiple advancers per stage
- **WHEN** multiple users are assigned as advancers to a stage
- **THEN** any one of them can independently advance or reject a candidate

#### Scenario: Non-advancer cannot advance
- **WHEN** a user who is not an advancer for a stage attempts to advance a candidate from that stage
- **THEN** the system prevents the action with a permission error

### Requirement: Minimum examiner requirement for interview stages
The system SHALL allow admins to set a minimum number of examiners required for interview-type stages.

#### Scenario: Set min_examiners
- **WHEN** an admin sets `min_examiners` to 3 on an interview-type stage
- **THEN** the value is saved
- **AND** interview scheduling for that stage requires at least 3 examiners to be available in the same slot

#### Scenario: min_examiners defaults to 1
- **WHEN** an admin creates an interview-type stage without setting min_examiners
- **THEN** min_examiners defaults to 1

#### Scenario: min_examiners on non-interview stages ignored
- **WHEN** min_examiners is set on a stage that is not of type "interview"
- **THEN** the value is saved but has no effect on scheduling or advancement

### Requirement: Role assignments are per-pipeline
The system SHALL maintain separate role assignments for each pipeline, so the same user can be an examiner in one pipeline's interview stage and an advancer in another.

#### Scenario: Independent role assignments across pipelines
- **WHEN** user A is an examiner for Pipeline 1's "Tech Interview" stage
- **AND** user A is an advancer for Pipeline 2's "Phone Screen" stage
- **THEN** the role assignments are independent and do not conflict
