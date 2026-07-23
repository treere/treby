# Activity Log

## Purpose

Provide a chronological history of all hiring actions on a candidate, so any team member can see what happened and when.

## Requirements

### Requirement: Log activity events
The system SHALL record key events to an activity log.

#### Scenario: Stage change logged
- **WHEN** an application is moved between pipeline stages
- **THEN** an activity log entry is created with action `application_stage_changed`, the actor, old stage, new stage, and timestamp

#### Scenario: Note created logged
- **WHEN** a note is added to an application
- **THEN** an activity log entry is created with action `note_created`, the actor, note type, and timestamp

#### Scenario: Interview scheduled logged
- **WHEN** an interview is scheduled
- **THEN** an activity log entry is created with action `interview_scheduled`, the actor, interviewer, date/time, and timestamp

#### Scenario: Interview cancelled logged
- **WHEN** an interview is cancelled
- **THEN** an activity log entry is created with action `interview_cancelled`, the actor, and timestamp

#### Scenario: Candidate created logged
- **WHEN** a candidate is created (manually or via public form)
- **THEN** an activity log entry is created with action `candidate_created`, the actor (or "External applicant" for public form), and timestamp

#### Scenario: Candidate updated logged
- **WHEN** a candidate's information is edited
- **THEN** an activity log entry is created with action `candidate_updated`, the actor, changed fields, and timestamp

### Requirement: Display activity timeline
The system SHALL display a chronological activity feed on the candidate profile page.

#### Scenario: Activity timeline on candidate profile
- **WHEN** a user views a candidate profile
- **THEN** the 20 most recent activity events for that candidate are shown in reverse chronological order
- **AND** each event shows: action description, actor name, and relative timestamp ("2 hours ago")

#### Scenario: Empty activity log
- **WHEN** a candidate has no activity events
- **THEN** the activity section shows "No activity yet" or is hidden
