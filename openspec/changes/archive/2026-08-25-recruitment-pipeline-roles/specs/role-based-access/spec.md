# Role-Based Access Control (delta)

## MODIFIED Requirements

### Requirement: Admin-only pipeline configuration
The system SHALL restrict pipeline stage management and role assignment to admin users.

#### Scenario: Admin manages pipeline stages
- **WHEN** an admin creates, edits, reorders, or deletes pipeline stages
- **THEN** the changes are applied

#### Scenario: Member attempts pipeline configuration
- **WHEN** a member attempts to create, edit, or delete pipeline stages
- **THEN** the system returns a permission error

#### Scenario: Admin manages stage roles
- **WHEN** an admin assigns examiners, reviewers, or advancers to pipeline stages
- **THEN** the assignments are saved

#### Scenario: Member attempts stage role assignment
- **WHEN** a member attempts to assign examiners, reviewers, or advancers to pipeline stages
- **THEN** the system returns a permission error

#### Scenario: Admin configures min_examiners
- **WHEN** an admin sets the minimum examiner count on an interview-type stage
- **THEN** the value is saved

## ADDED Requirements

### Requirement: Advancer-only stage advancement
The system SHALL restrict candidate advancement from a stage to assigned advancers only.

#### Scenario: Advancer advances candidate
- **WHEN** a user who is an advancer for the current stage attempts to advance a candidate
- **AND** all examiners have submitted scorecards (for interview-type stages)
- **THEN** the advancement proceeds

#### Scenario: Non-advancer attempts advancement
- **WHEN** a user who is not an advancer for the current stage attempts to advance a candidate
- **THEN** the system prevents the action with a permission error

### Requirement: Admin-only template management
The system SHALL restrict pipeline template creation, editing, and deletion to admin users.

#### Scenario: Admin manages templates
- **WHEN** an admin creates, edits, or deletes pipeline templates
- **THEN** the changes are applied

#### Scenario: Member attempts template management
- **WHEN** a member attempts to create, edit, or delete pipeline templates
- **THEN** the system returns a permission error
