## MODIFIED Requirements

### Requirement: Candidate views application details
The system SHALL allow candidates to view details of a specific application, including a clear progress panel showing where they are and what happens next, phrased in candidate-friendly language (no internal roles or blocker jargon).

#### Scenario: Application detail view
- **WHEN** candidate clicks on an application card
- **THEN** the system displays: job title, current stage, application date, source, and a timeline of status changes (system messages)

#### Scenario: Progress panel shows current step and what is next
- **WHEN** candidate views an application with no action pending on them
- **THEN** the progress panel shows their current step and the next step in the process (e.g. "You are scheduled for an interview", "Your application is under review")
- **AND** the panel does not reveal internal roles or internal blocker details

#### Scenario: Progress panel surfaces a pending action for the candidate
- **WHEN** candidate views an application
- **AND** there is an action pending on the candidate (e.g. replying to a request for more information, or choosing an interview time slot)
- **THEN** the progress panel highlights that action as pending on the candidate and links to where they can complete it

#### Scenario: Application with active conversation
- **WHEN** candidate views an application that has an active conversation
- **THEN** the system displays the conversation thread with all messages and a reply form at the bottom
