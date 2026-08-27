# Interview Completion

## Purpose

Add an explicit lifecycle step that closes a scheduled interview (status `scheduled` → `completed`), triggers the contextual scorecard invitation, and is the prerequisite for advancing from an interview stage.

## Requirements

### Requirement: Complete an interview explicitly
The system SHALL allow a scheduled interview to be marked as completed with one explicit action, transitioning the event status from "scheduled" to "completed". Completion SHALL NOT be inferred from scorecard submission and SHALL NOT by itself advance the application.

#### Scenario: Examiner or recruiter completes an interview
- **WHEN** an interview event has status "scheduled"
- **AND** an examiner, advancer, or recruiter triggers the complete action
- **THEN** the event status changes to "completed"
- **AND** the application remains in its current stage (it is not advanced by this action)

#### Scenario: Completion is a prerequisite for advancing
- **WHEN** an advancer attempts to advance an application from an interview-type stage
- **AND** the application's interview event is not yet completed
- **THEN** the advancement is blocked
- **AND** the progress state reports the `interview_not_completed` blocker

#### Scenario: Completed interview with all scorecards can advance
- **WHEN** an application's interview is completed
- **AND** all examiners have submitted their scorecards
- **THEN** advancement from the interview stage is permitted

### Requirement: Complete action availability
The system SHALL make the complete interview action available from the places where the team works: the pipeline card, the candidate detail page, and the interviews page.

#### Scenario: Complete action shown for authorized users
- **WHEN** an examiner, the scheduled-by user, an advancer, or a recruiter views an interview event with status "scheduled"
- **THEN** a "Mark as completed" action is shown for that event in the pipeline card, the candidate detail page, and the interviews page

### Requirement: Contextual scorecard invitation
The system SHALL prompt examiners to submit their scorecard in place, from the surfaces where the interview is seen, rather than requiring navigation to a separate page.

#### Scenario: Examiner prompted after completion
- **WHEN** an examiner who has not yet submitted their scorecard views an interview whose event is completed
- **THEN** the system shows a clear prompt and a scorecard form for that examiner to fill in place

#### Scenario: Examiner edits an existing scorecard
- **WHEN** an examiner who has already submitted their scorecard views that interview
- **THEN** the system shows the existing scorecard and allows it to be edited and resubmitted