# job-pipeline-editor Delta

## MODIFIED Requirements

### Requirement: Pipeline editor on job detail page
The system SHALL display a read-only pipeline overview on the job detail page listing the stages of the job's pipeline, with editing available through a "Manage Pipeline" action restricted to admins.

#### Scenario: Read-only stage overview
- **WHEN** a user opens a job detail page
- **THEN** a "Pipeline" section shows the stages of the job's pipeline in position order
- **AND** each stage shows its color, name, type, candidate count, and the names of its assigned examiners, reviewers, and advancers
- **AND** no editing controls are shown

#### Scenario: Effective pipeline resolution
- **WHEN** the job has an explicit `pipeline_id`
- **THEN** the overview uses that pipeline
- **AND** if the job has no explicit `pipeline_id`, the overview uses the tenant's default pipeline

#### Scenario: Manage Pipeline opens the editor
- **WHEN** an admin clicks "Manage Pipeline"
- **THEN** the pipeline editor is revealed with controls to add, edit, reorder, delete, and assign roles to stages

#### Scenario: Editing controls hidden by default
- **WHEN** a user opens a job detail page
- **THEN** stage editing controls are not visible until "Manage Pipeline" is activated