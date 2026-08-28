## MODIFIED Requirements

### Requirement: Schedule interview as recruiter
The system SHALL allow recruiters to schedule interviews from the application page, supporting multi-examiner events.

#### Scenario: Initiate scheduling
- **WHEN** a recruiter clicks "Schedule Interview" on an application page
- **THEN** the system displays a scheduling form with date picker and available slots
- **AND** for interview-type stages, the form shows slots computed from overlapping examiner availability

#### Scenario: Select slot and confirm (multi-examiner)
- **WHEN** a recruiter selects an available slot for a multi-examiner stage and confirms
- **THEN** the system creates a single Google Calendar event with a Google Meet link
- **AND** creates an `interview_event` record with status "scheduled"
- **AND** links all eligible examiners for that slot to the event
- **AND** notifies all examiners in-app (activity log)
- **AND** posts an interview message in the candidate's portal conversation with the date, time, interviewer, and Meet link
- **AND** moves the application to the interview pipeline stage

#### Scenario: Slot no longer available
- **WHEN** a recruiter tries to book a slot that was taken by another user
- **THEN** the system returns an error indicating the slot is no longer available
- **AND** refreshes the available slots list

### Requirement: Interview notifications
The system SHALL notify candidates and examiners about scheduled interviews without sending full-content emails to the candidate.

#### Scenario: Candidate notification
- **WHEN** an interview is scheduled for a candidate
- **THEN** the system posts a message in the candidate's portal conversation with the interview date/time, Google Meet link, and interviewer name
- **AND** if the candidate's `interview_update` preference is enabled, sends a short ping email: "There's an update regarding your interview for {job_title}" with a "View in Portal" button linking to `/:tenant_slug/portal`

#### Scenario: Interviewer notification
- **WHEN** an interview is scheduled with an interviewer
- **THEN** the system logs an in-app activity event with the interview date/time, candidate name, and Google Meet link
- **AND** no email is sent to the interviewer