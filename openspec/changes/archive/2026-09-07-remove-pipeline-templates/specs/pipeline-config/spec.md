# Pipeline Configuration (delta)

## Modified Requirements

### Requirement: Pipeline CRUD
The system SHALL allow admins to create, read, update, and delete pipeline
definitions. Pipeline templates no longer exist.

#### Scenario: No templates section in settings
- **WHEN** an admin navigates to Settings → Pipeline
- **THEN** only real pipelines are listed (no templates section, no New Template form)

### Requirement: Pipeline selector on jobs
The system SHALL allow assigning a pipeline when creating or editing a job.

#### Scenario: Create job without pipeline
- **WHEN** an admin creates a job without selecting a pipeline
- **THEN** the job uses the tenant's default pipeline (existing behavior, unchanged)

#### Scenario: No template option in job form
- **WHEN** an admin creates a job
- **THEN** no "Or start from a template" option is offered

### Requirement: Detach shared pipeline per job
The system SHALL give a job its own pipeline copy when its shared pipeline is
detached.

#### Scenario: Detach clone names stay unique
- **WHEN** a shared pipeline is detached for a job and a "<source> (Job)" pipeline already exists
- **THEN** the clone receives a numbered fallback name ("(Copy)", "(Copy 2)", …) instead of failing on the unique name constraint
