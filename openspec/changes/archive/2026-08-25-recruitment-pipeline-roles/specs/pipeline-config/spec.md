# Pipeline Configuration (delta)

## MODIFIED Requirements

### Requirement: Pipeline stage editor
The system SHALL provide a stage editor for each pipeline, including role assignment and minimum examiner configuration.

#### Scenario: Add stage to pipeline
- **WHEN** an admin adds a stage to a pipeline
- **THEN** the stage appears in the pipeline's stage list and on the Kanban board for jobs using that pipeline

#### Scenario: Reorder stages
- **WHEN** an admin reorders stages in a pipeline
- **THEN** the new order is saved and reflected on the Kanban board

#### Scenario: Set stage type
- **WHEN** an admin sets a stage's type to one of: new, interview, offer, hired, rejected
- **THEN** the stage is tagged with that type
- **AND** the type is used for auto-move logic and analytics

#### Scenario: Clear stage type
- **WHEN** an admin clears a stage's type
- **THEN** the stage has no type and is not used for auto-move logic

#### Scenario: Delete stage with no candidates
- **WHEN** an admin deletes a stage with no active candidates
- **THEN** the stage is removed from the pipeline

#### Scenario: Delete stage with candidates
- **WHEN** an admin deletes a stage that has active candidates
- **THEN** a reassignment modal appears listing all other stages in the pipeline
- **AND** the admin selects a destination stage for the candidates
- **AND** all candidates are moved to the selected stage
- **AND** the original stage is deleted

#### Scenario: Delete only stage with type "new"
- **WHEN** an admin tries to delete the only stage with type "new" in a pipeline
- **THEN** the system prevents deletion with a warning that new candidates are placed in this stage automatically

### Requirement: Duplicate pipeline
The system SHALL allow admins to duplicate an existing pipeline, including role assignments.

#### Scenario: Duplicate pipeline
- **WHEN** an admin duplicates a pipeline
- **THEN** a new pipeline is created with "(Copy)" appended to the name
- **AND** all stages from the original are copied with the same names, positions, colors, stage_types, min_examiners, and scorecard template associations
- **AND** all examiner, reviewer, and advancer assignments are copied to the new pipeline
- **AND** the new pipeline is not marked as default

## ADDED Requirements

### Requirement: Configure min_examiners on stage
The system SHALL allow admins to set a minimum number of examiners for interview-type stages.

#### Scenario: Set min_examiners
- **WHEN** an admin sets the minimum examiner count on an interview-type stage
- **THEN** the value is saved and used for scheduling availability computation

#### Scenario: min_examiners defaults to 1
- **WHEN** an admin creates an interview-type stage without specifying min_examiners
- **THEN** the value defaults to 1

### Requirement: Assign examiners, reviewers, and advancers to stage
The system SHALL allow admins to assign users to specific roles within each pipeline stage.

#### Scenario: Open role assignment panel
- **WHEN** an admin clicks on a stage in the pipeline editor
- **THEN** a role assignment panel is displayed showing lists of users available for each role (examiner, reviewer, advancer)

#### Scenario: Assign user to role
- **WHEN** an admin selects a user and assigns them to a role (examiner, reviewer, or advancer) on a stage
- **THEN** the assignment is saved
- **AND** the user appears in the stage's role list

#### Scenario: Remove user from role
- **WHEN** an admin removes a user from a role on a stage
- **THEN** the assignment is removed
- **AND** the user no longer has that role for that stage

#### Scenario: Assign scorecard template to stage
- **WHEN** an admin associates a scorecard template with a stage
- **THEN** the association is saved
- **AND** interviewers for that stage will use that template when filling out scorecards
