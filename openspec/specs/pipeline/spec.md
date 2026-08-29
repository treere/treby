# Pipeline

## Purpose

Provide a Kanban-style pipeline board for managing candidates through hiring stages with real-time collaboration.

## Requirements

### Requirement: Kanban board view
The system SHALL display a Kanban board for each job showing candidates in pipeline stages from the job's assigned pipeline.

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

### Requirement: Candidate cards link to candidate details
The system SHALL allow users to navigate from a pipeline candidate card to the candidate's detail page.

#### Scenario: Click candidate card opens details
- **WHEN** a user clicks a candidate card in the pipeline board
- **THEN** the system navigates to `/app/candidates/:candidate_id`
- **AND** displays the candidate's details, applications, interviews, notes, and activity

#### Scenario: Drag-and-drop remains functional
- **WHEN** a user drags a candidate card between stages
- **THEN** the click navigation does not interfere with the drag-and-drop interaction

### Requirement: Drag-and-drop stage transition
The system SHALL allow dragging candidate cards between stages. For interview-type stages, advancement is restricted to assigned advancers and requires all examiners to have submitted scorecards.

#### Scenario: Move candidate to new stage
- **WHEN** a user drags a candidate card from one stage column to another
- **THEN** the candidate's application is updated to the new stage
- **AND** the change is reflected in real-time for all connected users

#### Scenario: Drop in same stage
- **WHEN** a user drops a card in the same stage column
- **THEN** no change is made

#### Scenario: Advance from interview stage requires scorecards
- **WHEN** a user attempts to advance a candidate from an interview-type stage
- **AND** not all examiners for that stage have submitted their scorecards
- **THEN** the system prevents the advancement
- **AND** displays a message indicating which examiners still need to submit feedback

#### Scenario: Advance from interview stage with all scorecards
- **WHEN** a user attempts to advance a candidate from an interview-type stage
- **AND** all examiners have submitted their scorecards
- **THEN** the advancement proceeds normally

#### Scenario: Only advancers can advance from stage
- **WHEN** a user who is not an advancer for the current stage attempts to advance a candidate
- **THEN** the system prevents the action with a permission error

### Requirement: Pipeline stages management
The system SHALL allow admins to customize pipeline stages.

#### Scenario: Add new stage
- **WHEN** an admin adds a new pipeline stage
- **THEN** the stage appears on the Kanban board

#### Scenario: Remove stage
- **WHEN** an admin removes a pipeline stage with no candidates
- **THEN** the stage is deleted from the board

#### Scenario: Remove stage with candidates
- **WHEN** an admin removes a stage with candidates
- **THEN** a reassignment modal is displayed listing other stages in the pipeline
- **AND** the admin selects a destination stage for the candidates
- **AND** all candidates are moved to the selected stage
- **AND** the original stage is deleted

### Requirement: Application review state
The system SHALL track and display whether applications have been reviewed.

#### Scenario: Review badge on pipeline card
- **WHEN** an application has `reviewed = false`
- **THEN** a "NEW" badge is displayed on the pipeline card

#### Scenario: Toggle review state
- **WHEN** a user clicks the review toggle on a pipeline card
- **THEN** the application's `reviewed` field is toggled between `true` and `false`

#### Scenario: Filter by review state
- **WHEN** a user selects "New only" from the pipeline filter
- **THEN** only cards with `reviewed = false` are shown in each stage

#### Scenario: Default review state for new applications
- **WHEN** a new application is created (via public form or manual)
- **THEN** `reviewed` defaults to `false`

### Requirement: Real-time updates
The system SHALL broadcast pipeline changes to all connected clients.

#### Scenario: Multi-user real-time sync
- **WHEN** one user moves a candidate to a new stage
- **THEN** all other users viewing the same pipeline see the change immediately

### Requirement: Pipeline selector on analytics
The system SHALL allow selecting which pipeline to view in analytics.

#### Scenario: Pipeline dropdown
- **WHEN** a user navigates to the analytics page
- **THEN** a dropdown shows all pipelines for the tenant plus an "All pipelines" option
- **AND** the default selection is "All pipelines"

#### Scenario: Select specific pipeline
- **WHEN** a user selects a specific pipeline from the dropdown
- **THEN** the analytics data updates to show only that pipeline's jobs and candidates

#### Scenario: Select all pipelines
- **WHEN** a user selects "All pipelines"
- **THEN** the analytics data aggregates across all pipelines

### Requirement: Time-in-stage metrics
The system SHALL track and display how long candidates spend in each pipeline stage.

#### Scenario: Average time per stage
- **WHEN** a user views analytics
- **THEN** the average time (in days) candidates spend in each stage is displayed
- **AND** stages with no completed transitions show "N/A"

#### Scenario: Time-in-stage per pipeline
- **WHEN** a user selects a specific pipeline in analytics
- **THEN** the time-in-stage metrics reflect only that pipeline's data

#### Scenario: Bottleneck indicator
- **WHEN** a user views time-in-stage metrics
- **THEN** stages with above-average time are visually highlighted as potential bottlenecks

### Requirement: Bulk move candidates
The system SHALL allow moving multiple selected candidates to a stage simultaneously. The stages offered SHALL be the effective pipeline's stages for the currently viewed job. The bulk action bar stage selector and move button SHALL be wired through a form so the dropdown populates without client-side errors.

#### Scenario: Bulk move via selection
- **WHEN** a user selects multiple candidate cards and chooses "Move to Stage"
- **THEN** a dropdown of available stages is shown
- **AND** confirming moves all selected applications to the chosen stage

#### Scenario: Bulk move controls inside a form
- **WHEN** a user opens the bulk action bar on the pipeline board
- **THEN** the stage selector and move button are inside a form element
- **AND** no "form events require the input to be inside a form" error is raised in the browser console

#### Scenario: Bulk move dropdown populated per job
- **WHEN** a user opens the bulk action bar on a pipeline board for a job without an explicit pipeline
- **THEN** the dropdown lists the tenant's default pipeline stages for that job

#### Scenario: Bulk move disabled without stages
- **WHEN** the job's effective pipeline has no stages
- **THEN** the "Move to Stage" option is disabled

#### Scenario: Bulk move with email notification
- **WHEN** the target stage has an email template and the user chooses to send
- **THEN** emails are sent to all selected candidates
- **AND** a summary is shown: "X moved, Y emails sent"

### Requirement: Bulk mark reviewed
The system SHALL allow marking multiple selected applications as reviewed or unreviewed.

#### Scenario: Bulk mark reviewed
- **WHEN** a user selects candidate cards and clicks "Mark as Reviewed"
- **THEN** all selected applications have `reviewed` set to `true`

#### Scenario: Bulk mark unreviewed
- **WHEN** a user selects reviewed candidate cards and clicks "Mark as New"
- **THEN** all selected applications have `reviewed` set to `false`

### Requirement: Advance or reject candidate from stage
The system SHALL allow assigned advancers to manually advance or reject candidates from a stage. Rejection SHALL target the stage with `stage_type = "rejected"` in the job's effective pipeline, resolved even when the job has no explicit pipeline.

#### Scenario: Advance candidate
- **WHEN** an advancer clicks "Advance" on a candidate in their stage
- **THEN** the candidate moves to the next stage in the pipeline

#### Scenario: Reject candidate with motivation
- **WHEN** an advancer clicks "Reject" on a candidate in their stage
- **THEN** the system prompts for a rejection motivation
- **AND** upon confirmation, the candidate is marked as rejected with the motivation
- **AND** the candidate is removed from the active pipeline

#### Scenario: Reject candidate in default-pipeline job
- **WHEN** an advancer rejects a candidate in a job that has no explicit pipeline
- **THEN** the system resolves the tenant's default pipeline stages
- **AND** the candidate is moved to the stage with `stage_type = "rejected"` and removed from the active pipeline

#### Scenario: Reject requires motivation
- **WHEN** an advancer attempts to reject a candidate without providing a motivation
- **THEN** the system prevents the rejection and prompts for a motivation

#### Scenario: Reject when pipeline has no rejected stage
- **WHEN** the effective pipeline has no stage with `stage_type = "rejected"`
- **THEN** the reject action is disabled with a message explaining a rejected stage is required

### Requirement: Kanban access for advanced operations
The system SHALL keep the per-job Kanban board accessible from the job detail page as a secondary entry point for advanced operations such as drag-and-drop moves, bulk actions, scheduling, and scorecards.

#### Scenario: Open Kanban from job page
- **WHEN** a user clicks the pipeline entry on a job detail page
- **THEN** the Kanban board for that job is shown

#### Scenario: Secondary entry styling
- **WHEN** a user views a job detail page
- **THEN** the Kanban entry is styled as a secondary action, distinct from primary page actions
