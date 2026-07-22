## ADDED Requirements

### Requirement: Pipeline CRUD
The system SHALL allow admins to create, read, update, and delete pipeline definitions.

#### Scenario: List pipelines
- **WHEN** an admin navigates to Settings > Pipeline
- **THEN** a list of all pipelines for the tenant is displayed
- **AND** each pipeline shows its name, stage count, and active job count

#### Scenario: Create pipeline
- **WHEN** an admin creates a new pipeline with a name
- **THEN** the pipeline is created with no stages
- **AND** the pipeline appears in the pipeline list

#### Scenario: Edit pipeline name
- **WHEN** an admin renames a pipeline
- **THEN** the new name is saved and reflected in the list

#### Scenario: Delete pipeline
- **WHEN** an admin deletes a pipeline with no active jobs
- **THEN** the pipeline and its stages are removed

#### Scenario: Delete pipeline with active jobs
- **WHEN** an admin deletes a pipeline that has active jobs
- **THEN** a confirmation modal shows the affected jobs
- **AND** upon confirmation, all affected jobs are moved to the tenant's default pipeline
- **AND** the pipeline and its stages are removed

#### Scenario: Cannot delete last pipeline
- **WHEN** a tenant has only one pipeline
- **THEN** the delete action is disabled with a tooltip explaining at least one pipeline is required

### Requirement: Default pipeline
The system SHALL designate exactly one pipeline as the default per tenant.

#### Scenario: Set default pipeline
- **WHEN** an admin sets a pipeline as default
- **THEN** the previous default pipeline loses its default status
- **AND** the new default is indicated in the pipeline list

#### Scenario: New jobs use default pipeline
- **WHEN** a job is created without specifying a pipeline
- **THEN** the job uses the tenant's default pipeline

### Requirement: Duplicate pipeline
The system SHALL allow admins to duplicate an existing pipeline.

#### Scenario: Duplicate pipeline
- **WHEN** an admin duplicates a pipeline
- **THEN** a new pipeline is created with "(Copy)" appended to the name
- **AND** all stages from the original are copied with the same names, positions, colors, and stage_types
- **AND** the new pipeline is not marked as default

### Requirement: Pipeline stage editor
The system SHALL provide a stage editor for each pipeline.

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

### Requirement: Pipeline selector on jobs
The system SHALL allow assigning a pipeline when creating or editing a job.

#### Scenario: Create job with pipeline
- **WHEN** an admin creates a job and selects a pipeline
- **THEN** the job uses the selected pipeline for its Kanban board

#### Scenario: Create job without pipeline
- **WHEN** an admin creates a job without selecting a pipeline
- **THEN** the job uses the tenant's default pipeline

#### Scenario: Change job pipeline
- **WHEN** an admin changes a job's pipeline
- **THEN** the Kanban board for that job updates to show the new pipeline's stages
- **AND** existing applications retain their `pipeline_stage_id` (candidates may appear in columns that no longer exist for that pipeline)
