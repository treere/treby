# job-pipeline-editor Specification

## Purpose
TBD - created by archiving change edit-job-pipeline-from-job-page. Update Purpose after archive.
## Requirements
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

### Requirement: Job pipeline stays dedicated to the job
The system SHALL keep the job's pipeline dedicated to that job so stage edits never affect other jobs.

#### Scenario: Job created from a template
- **WHEN** a job's pipeline was created from a template (already cloned and dedicated)
- **THEN** editing stages from the job page modifies that pipeline directly without cloning again

#### Scenario: Job using a shared pipeline
- **WHEN** an admin edits a stage from the job page
- **AND** the job uses a pipeline that is shared with other active jobs
- **THEN** the system first clones the pipeline for that job and reassigns the job to the clone
- **AND** the original pipeline and other jobs using it are unchanged
- **AND** the edited job's Kanban board continues to show the same stages after the clone

#### Scenario: Job implicitly using the default pipeline
- **WHEN** an admin edits a stage from the job page
- **AND** the job has no explicit pipeline (implicitly using the tenant default)
- **THEN** the system clones the default pipeline for the job before applying the edit
- **AND** the tenant's default pipeline is unchanged

### Requirement: Add stage to job pipeline
The system SHALL allow admins to add a stage to the job's pipeline from the job page.

#### Scenario: Add new stage
- **WHEN** an admin adds a stage with a name and type from the job page
- **THEN** the stage is appended to the end of the job's pipeline
- **AND** the stage appears in the job page's pipeline list and on the job's Kanban board

### Requirement: Edit stage in job pipeline
The system SHALL allow admins to edit the name, type, color, minimum examiners, and scorecard template of a stage from the job page.

#### Scenario: Update stage fields
- **WHEN** an admin edits a stage and changes its name, type, color, min examiners, or scorecard template
- **THEN** the changes are saved
- **AND** reflected in the job page's pipeline list

#### Scenario: Interview-only fields
- **WHEN** the stage's type is "interview"
- **THEN** the editor shows fields for min examiners and scorecard template

### Requirement: Reorder stages in job pipeline
The system SHALL allow admins to reorder the stages of the job's pipeline from the job page.

#### Scenario: Move stage up
- **WHEN** an admin moves a stage up
- **THEN** the stage's position increases by one
- **AND** the new order is reflected on the Kanban board

#### Scenario: Move stage down
- **WHEN** an admin moves a stage down
- **THEN** the stage's position decreases by one
- **AND** the new order is reflected on the Kanban board

### Requirement: Delete stage in job pipeline
The system SHALL allow admins to delete a stage from the job's pipeline from the job page, handling candidates appropriately.

#### Scenario: Delete stage with no candidates
- **WHEN** an admin deletes a stage with no active candidates
- **THEN** the stage is removed from the job's pipeline

#### Scenario: Delete stage with candidates
- **WHEN** an admin deletes a stage that has active candidates
- **THEN** a reassignment modal shows the other stages in the pipeline
- **AND** the admin selects a destination stage
- **AND** all candidates are moved to the selected stage
- **AND** the original stage is deleted

#### Scenario: Delete only entry stage blocked
- **WHEN** an admin tries to delete the only stage of type "new" in the pipeline
- **THEN** the system prevents deletion with a warning

### Requirement: Assign stage roles from job page
The system SHALL allow admins to assign and remove examiners, reviewers, and advancers for a stage from the job page.

#### Scenario: Open role panel
- **WHEN** an admin clicks "Roles" on an interview-type stage
- **THEN** a panel is displayed listing available users for each role (examiner, reviewer, advancer)

#### Scenario: Assign user to role
- **WHEN** an admin assigns a user to a role on a stage
- **THEN** the assignment is saved
- **AND** the user appears in the stage's role list

#### Scenario: Remove user from role
- **WHEN** an admin removes a user from a role on a stage
- **THEN** the assignment is removed
- **AND** the user no longer has that role for that stage

### Requirement: Job pipeline editor admin access
The system SHALL restrict stage mutations from the job page to admins.

#### Scenario: Admin can edit stages
- **WHEN** an admin opens the job page and edits a stage
- **THEN** the edit is applied

#### Scenario: Non-admin cannot edit stages
- **WHEN** a non-admin user opens the job page
- **THEN** the stage edit affordances are not available
- **AND** the user cannot mutate pipeline stages

