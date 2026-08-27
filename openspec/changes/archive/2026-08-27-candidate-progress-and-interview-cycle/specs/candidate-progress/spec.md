## ADDED Requirements

### Requirement: Current application progress state
The system SHALL provide a single, transparent view of an application's progress: the current pipeline stage, whether advancement is blocked, what is blocking it, and the concrete next actions. This state SHALL be computed on the fly from existing data (stage, interview events, examiners, scorecards, minimum examiners) and SHALL require no automation.

#### Scenario: Application in a non-interview stage with no blockers
- **WHEN** an application is in a stage that is not interview-type and has no conditions required to advance
- **THEN** the progress state reports `blocked? = false`
- **AND** reports no blockers
- **AND** reports the next action as advancing to the next stage

#### Scenario: Application in an interview stage with an uncompleted interview
- **WHEN** an application is in an interview-type stage
- **AND** its interview event has status "scheduled" (not yet completed)
- **THEN** the progress state reports `blocked? = true`
- **AND** includes a blocker of kind `interview_not_completed`

#### Scenario: Application in an interview stage with missing scorecards
- **WHEN** an application is in an interview-type stage
- **AND** its interview is completed
- **AND** not all examiners have submitted their scorecards
- **THEN** the progress state reports `blocked? = true`
- **AND** includes one blocker of kind `scorecard_pending` for each examiner who has not yet submitted, naming that examiner

#### Scenario: Application in an interview stage fully resolved
- **WHEN** an application is in an interview-type stage
- **AND** its interview is completed
- **AND** all examiners have submitted their scorecards
- **THEN** the progress state reports `blocked? = false`
- **AND** reports no blockers

#### Scenario: Progress counts
- **WHEN** any progress state is computed for an application in an interview stage
- **THEN** the state reports the scorecard progress as `completed` / `total` (e.g. "2/3")
- **AND** reports the interview progress as scheduled and completed counts

### Requirement: Team sees progress and blockers on pipeline cards
The system SHALL surface an application's progress state and its blockers on the Kanban pipeline board so advancers and recruiters can see exactly what is missing and who must act.

#### Scenario: Card shows blockers instead of an opaque count
- **WHEN** an application in an interview stage has pending examiners
- **THEN** the pipeline card lists each pending examiner by name (e.g. "Caio: scorecard mancante") instead of only a "X/Y scorecards" counter
- **AND** if the interview is not yet completed, the card also shows the "interview not yet completed" blocker

#### Scenario: Card shows ready-to-advance state
- **WHEN** an application's progress state reports `blocked? = false`
- **AND** the current user is an advancer for the stage
- **THEN** the card clearly indicates the candidate is ready to advance

### Requirement: Candidate detail surfaces progress and next actions
The system SHALL show the same progress state on the candidate detail page, with an actionable list of next steps for the team (complete interview, nudge an examiner, submit own scorecard) so the person deciding does not have to reconstruct the state manually.

#### Scenario: Detail page shows next actions
- **WHEN** a recruiter or advancer views a candidate's application detail
- **THEN** the page shows a progress panel listing current stage, blockers, and the concrete next actions with assignees
