# Job Page Candidate Management

## Purpose

Make the job detail page a self-sufficient daily workspace by grouping candidates per pipeline stage and enabling inline management (stage moves, rejection, contextual badges, search) directly on the page.

## Requirements

### Requirement: Candidates grouped by pipeline stage
The system SHALL display candidates on the job detail page grouped by their current pipeline stage, in stage position order, with a count per stage.

#### Scenario: Candidates shown per stage
- **WHEN** a user views a job with applications in multiple stages
- **THEN** the candidates section shows one column per stage in the pipeline's position order
- **AND** each stage header shows the stage name and the number of candidates in it

#### Scenario: Stage with no candidates
- **WHEN** a pipeline stage has no candidates
- **THEN** its column is displayed with a count of zero and an empty state

#### Scenario: Job with no candidates
- **WHEN** a user views a job with no applications
- **THEN** the candidates section shows an empty state message

#### Scenario: Effective pipeline resolution
- **WHEN** a job has no explicit pipeline
- **THEN** candidates are grouped using the tenant's default pipeline stages

### Requirement: Candidate card links to profile
The system SHALL link each job-page candidate card to the candidate's profile page.

#### Scenario: Open candidate profile
- **WHEN** a user clicks a candidate name on a job-page card
- **THEN** the system navigates to the candidate's profile page
- **AND** the profile's back link returns to the originating job page

### Requirement: Inline stage change
The system SHALL allow changing a candidate's stage directly from the job page using a per-card stage selector. The selector SHALL be wired through a form so the change is dispatched without client-side errors.

#### Scenario: Move candidate to another stage
- **WHEN** a user selects a different stage in a candidate card's selector
- **THEN** the application is moved to the selected stage
- **AND** the card appears in the new stage's column

#### Scenario: Selector wired through a form
- **WHEN** a user opens the job detail page
- **THEN** each candidate card's stage selector is inside a form element
- **AND** no "form events require the input to be inside a form" error is raised in the browser console when changing the stage

#### Scenario: Move requires advancer for interview stages
- **WHEN** a user who is not an advancer for an interview stage attempts to move a candidate
- **THEN** the move is prevented
- **AND** the selector is disabled for that stage

#### Scenario: Single-stage pipeline
- **WHEN** the job's effective pipeline has a single stage
- **THEN** the stage selector is disabled

#### Scenario: Real-time update on Kanban
- **WHEN** a user moves a candidate from the job page
- **THEN** the Kanban board for that job reflects the change for all connected users

### Requirement: Reject candidate from job page
The system SHALL allow assigned advancers to reject a candidate directly from the job page, using the same rejection flow as the Kanban board.

#### Scenario: Reject with motivation
- **WHEN** an advancer clicks Reject on a job-page card
- **AND** provides a rejection motivation
- **THEN** the candidate moves to the rejected stage with the motivation recorded
- **AND** the rejection conversation and notification are created

#### Scenario: Reject requires motivation
- **WHEN** a user attempts to reject a candidate without a motivation
- **THEN** the system prevents the rejection and prompts for a motivation

#### Scenario: No rejected stage
- **WHEN** the effective pipeline has no stage with `stage_type = "rejected"`
- **THEN** the reject action is disabled with an explanatory message

#### Scenario: Non-advancer cannot reject
- **WHEN** a user who is not an advancer for the current stage attempts to reject
- **THEN** the reject action is not available

### Requirement: Contextual badges on job-page cards
The system SHALL show contextual indicators on job-page candidate cards.

#### Scenario: Duplicate application badge
- **WHEN** a candidate has more than one application to the job
- **THEN** a DUPLICATE badge is shown on the card

#### Scenario: Other positions indicator
- **WHEN** a candidate has applications to other jobs
- **THEN** the card shows "Also in N other positions"

#### Scenario: Upcoming interview indicator
- **WHEN** a candidate has a scheduled interview for the job
- **THEN** the card shows the interview date and time

#### Scenario: Resume link
- **WHEN** a candidate's application has a resume
- **THEN** the card shows a link to view the resume

### Requirement: Search within job candidates
The system SHALL allow searching among the job's candidates by name or email.

#### Scenario: Filter by name or email
- **WHEN** a user types a search term in the candidates section
- **THEN** only cards matching the term by name or email are shown

#### Scenario: No matches
- **WHEN** no candidate matches the search term
- **THEN** the section shows an empty state for the search