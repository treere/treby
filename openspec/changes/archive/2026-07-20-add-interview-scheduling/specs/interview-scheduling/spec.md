## ADDED Requirements

### Requirement: Compute available interview slots
The system SHALL compute available time slots by combining availability rules with Google Calendar free/busy data.

#### Scenario: Available slots with no conflicts
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** the interviewer's Google Calendar shows no busy periods
- **THEN** the system returns 30-minute slots from 09:00 to 17:00 (minus buffer times)

#### Scenario: Available slots with calendar conflicts
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** the interviewer's Google Calendar shows a busy period from 10:00-11:00
- **THEN** the system returns slots that do not overlap with the busy period or its buffer zones

#### Scenario: Available slots across multiple days
- **WHEN** a user requests available slots for a date range spanning multiple days
- **THEN** the system returns slots for each day where the interviewer has availability rules defined

#### Scenario: No availability rules for a day
- **WHEN** a user requests available slots for a day where the interviewer has no availability rules
- **THEN** no slots are returned for that day

### Requirement: Schedule interview as recruiter
The system SHALL allow recruiters to schedule interviews from the application page.

#### Scenario: Initiate scheduling
- **WHEN** a recruiter clicks "Schedule Interview" on an application page
- **THEN** the system displays a scheduling form with interviewer selection and date picker

#### Scenario: Select interviewer and view availability
- **WHEN** a recruiter selects an interviewer and date range
- **THEN** the system displays available 30-minute slots computed from availability rules and calendar free/busy

#### Scenario: Book a slot
- **WHEN** a recruiter selects an available slot and confirms
- **THEN** the system creates a Google Calendar event with a Google Meet link on both the interviewer's and candidate's calendars
- **AND** creates an `interview_event` record with status "scheduled"
- **AND** sends an email to the candidate with the Meet link and interview details
- **AND** moves the application to the "Interview" pipeline stage

#### Scenario: Slot no longer available
- **WHEN** a recruiter tries to book a slot that was taken by another user
- **THEN** the system returns an error indicating the slot is no longer available
- **AND** refreshes the available slots list

### Requirement: Google Meet event creation
The system SHALL create Google Calendar events with auto-generated Google Meet links.

#### Scenario: Event with Meet link
- **WHEN** an interview is scheduled
- **THEN** the system creates a Google Calendar event using the `conferenceData.createRequest` parameter
- **AND** the event includes a Google Meet video conference link
- **AND** the Meet link is stored in the `interview_events.video_conf_url` field

#### Scenario: Event creation failure
- **WHEN** the Google Calendar API fails to create an event
- **THEN** the system displays an error to the user
- **AND** does not create an `interview_event` record
- **AND** does not move the application to a new stage

### Requirement: Interview notifications
The system SHALL send email notifications when interviews are scheduled.

#### Scenario: Candidate notification
- **WHEN** an interview is scheduled for a candidate
- **THEN** the system sends an email to the candidate with the interview date/time, Google Meet link, and interviewer name

#### Scenario: Interviewer notification
- **WHEN** an interview is scheduled with an interviewer
- **THEN** the system sends an email to the interviewer with the interview date/time, candidate name, and Google Meet link

### Requirement: Cancel interview
The system SHALL allow cancelling scheduled interviews.

#### Scenario: Cancel interview
- **WHEN** a user cancels a scheduled interview
- **THEN** the system updates the `interview_event` status to "cancelled"
- **AND** deletes the Google Calendar event
- **AND** the application remains in its current pipeline stage (does not move back)

### Requirement: Interviews dashboard
The system SHALL display upcoming interviews.

#### Scenario: View upcoming interviews
- **WHEN** a user navigates to the interviews page
- **THEN** a list of upcoming interviews (status "scheduled") is displayed sorted by date
- **AND** each entry shows candidate name, job title, interviewer, date/time, and Meet link

#### Scenario: Filter by interviewer
- **WHEN** a user filters interviews by a specific interviewer
- **THEN** only interviews where that user is the interviewer are shown
