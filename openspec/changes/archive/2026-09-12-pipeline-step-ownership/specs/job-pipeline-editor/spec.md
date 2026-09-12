## MODIFIED Requirements

### Requirement: Pipeline editor on job detail page
The system SHALL display a read-only pipeline overview on the job detail page listing the stages of the job's pipeline, with editing available through a "Manage Pipeline" action restricted to admins. The overview SHALL always show an explicit owner line per stage (with "Everyone" fallback when unassigned), a visible legend for the three roles, and a short explainer of how the pipeline works.

#### Scenario: Read-only stage overview
- **WHEN** a user opens a job detail page
- **THEN** a "Pipeline" section shows the stages of the job's pipeline in position order
- **AND** each stage shows its color, name, type, candidate count, and an explicit owner line (assigned names with full role labels, or "Everyone" when no one is assigned)
- **AND** no editing controls are shown

#### Scenario: Legend visible in overview
- **WHEN** a user views the read-only pipeline overview on the job detail page
- **THEN** a one-line legend above the stage list explains Examiner, Reviewer, and Advancer roles

#### Scenario: How-it-works explainer
- **WHEN** a user views the Pipeline section on the job detail page
- **THEN** a short explainer is visible stating that stages are ordered, what stage types mean at a high level, and that editing stages here creates a job-dedicated pipeline copy that does not affect other jobs

#### Scenario: Everyone fallback in overview
- **WHEN** a stage has no examiners, reviewers, or advancers assigned
- **THEN** the overview shows "Responsible: Everyone" (localized as "Tutti" in Italian) instead of hiding the ownership line

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

#### Scenario: Editor ownership consistent with overview
- **WHEN** an admin opens the editor
- **THEN** each stage in the editor list shows the same explicit owner line (names with full labels or "Everyone") as the overview, not just compact counts

### Requirement: Job pipeline stays dedicated to the job
The system SHALL keep the job's pipeline dedicated to that job so stage edits never affect other jobs.

#### Scenario: Job with an already-dedicated pipeline
- **WHEN** a job's pipeline is already dedicated to that job (e.g. previously duplicated or detached)
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
