# Dashboard My Actions

## Purpose

Give each team member a single, actionable view of their own outstanding hiring work on the dashboard, so they don't have to scan the whole pipeline board to discover what is expected of them. This is facilitation of the manual flow only — no automation, no AI, no automatic decisions.

## Requirements

### Requirement: Pending scorecards for the current user
The system SHALL display, on the dashboard, the scorecards the current user still needs to submit as an examiner.

#### Scenario: User has a pending scorecard
- **WHEN** the current user is an examiner on an interview event
- **AND** their scorecard for that event has not been submitted
- **THEN** the event appears in a "My Actions" list on the dashboard
- **AND** the entry shows the candidate name, job title, interview date, and a direct "Fill scorecard" action

#### Scenario: No pending scorecards
- **WHEN** the current user has no missing scorecards
- **THEN** the "My Actions" list shows an empty state ("All caught up" or similar)

#### Scenario: Completed scorecards are not listed
- **WHEN** the current user has already submitted their scorecard for an event
- **THEN** that event does not appear in the pending list

#### Scenario: Only the user's own scorecards are shown
- **WHEN** another examiner's scorecard is missing for an event
- **THEN** that missing scorecard is NOT shown as an action for the current user

### Requirement: Direct scorecard action
The system SHALL let the user fill a pending scorecard directly from the dashboard, reusing the existing scorecard flow.

#### Scenario: Fill scorecard from dashboard
- **WHEN** the user clicks "Fill scorecard" on a pending action
- **THEN** the existing scorecard form for that interview event opens with the user's current responses pre-populated (or empty if none)
- **AND** submitting it records the scorecard for that examiner and event, and removes the item from the pending list

### Requirement: Waiting-on-others visibility
The system SHALL show a read-only list of applications whose progress is blocked by other people's outstanding work, so the user understands why things are stuck.

#### Scenario: Blocked by other examiners' scorecards
- **WHEN** an application is at an interview stage with the interview completed
- **AND** one or more scorecards from OTHER examiners are still missing
- **THEN** the application appears in the read-only list with an indication of who/what is pending (e.g., "Waiting on scorecards from [names]")

#### Scenario: Blocked by incomplete interview
- **WHEN** an application is at an interview stage and the interview has not been marked completed
- **THEN** the application appears in the read-only list indicating the interview is not yet completed

#### Scenario: Read-only, no action
- **WHEN** an application is shown in the waiting-on-others list
- **THEN** it is displayed without any action control

### Requirement: Role-permission consistency
The system SHALL only show actions the current user is authorized to perform, consistent with existing pipeline permissions.

#### Scenario: Actions match user permissions
- **WHEN** the dashboard shows a pending scorecard action for the user
- **THEN** the user is in fact an examiner on that event (consistent with the existing scorecard submission rules)