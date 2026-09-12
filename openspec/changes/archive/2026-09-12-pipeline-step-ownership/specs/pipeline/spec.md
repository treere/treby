## MODIFIED Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages from the job's assigned pipeline. Each stage header SHALL make the responsible owner(s) visible; when no specific users are assigned to any role for that stage, the header SHALL show an explicit "Everyone" fallback rather than an empty state.

#### Scenario: Pipeline board loads
- **WHEN** a user navigates to the pipeline for a specific job from the Jobs page
- **THEN** a Kanban board is displayed with columns for each stage in the job's assigned pipeline
- **AND** if the job has no explicit pipeline, the tenant's default pipeline is used

#### Scenario: Candidates shown in columns
- **WHEN** the pipeline board loads
- **THEN** each candidate card appears in the column matching their current stage

#### Scenario: Interview stage indicator
- **WHEN** a candidate card is in a stage with type "interview"
- **THEN** the card shows a camera icon indicating an interview is scheduled
- **AND** if an interview is scheduled, the card shows the interview date/time

#### Scenario: Standalone pipeline page removed
- **WHEN** a user opens the top-level Pipeline URL
- **THEN** there is no top-level `/app/pipeline` landing page
- **AND** the pipeline is only reachable per job (e.g. `/app/pipeline/:job_id`)

#### Scenario: Stage ownership visible on board
- **WHEN** a user views a pipeline stage column
- **THEN** the column header shows who is responsible for that stage (e.g., "Advancers: Anna, Luca" or "Responsible: Everyone" when no one is assigned)

#### Scenario: Everyone fallback on board
- **WHEN** a stage has no examiners, reviewers, or advancers assigned
- **THEN** the ownership line shows "Everyone" instead of an empty gap

### Requirement: Per-Stage Permissions
The system SHALL allow each stage to have three role assignments (Examiner, Reviewer, Advancer) and SHALL display ownership with full role labels and a visible legend explaining the three roles. The table below defines each role:

| Role | Who | What they can do |
|---|---|---|
| **Examiner** | Runs the interviews | Conducts interviews and fills out scorecards |
| **Reviewer** | Reviews applications | Reviews and leaves feedback |
| **Advancer** | Decides | Advances or rejects candidates in that stage |

Only advancers SHALL be able to advance or reject in interview stages; in other stages anyone SHALL be able to move. The UI SHALL use full role labels (not single-letter abbreviations) wherever ownership is displayed.

#### Scenario: Legend visible
- **WHEN** a user views the pipeline ownership area (job detail overview or board)
- **THEN** a one-line legend explains Examiner, Reviewer, and Advancer

#### Scenario: Full role labels
- **WHEN** a stage shows assigned users
- **THEN** each name is shown with its full role label (e.g., "Examiner: Mario Rossi") rather than a single-letter prefix

#### Scenario: Ownership fallback
- **WHEN** a stage has no users assigned to any role
- **THEN** the ownership line shows "Everyone" (localized) instead of hiding the line
