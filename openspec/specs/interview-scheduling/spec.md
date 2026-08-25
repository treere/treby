# Interview Scheduling

## Purpose

Enable recruiters and candidates to schedule interviews with availability computation, calendar integration, and notifications.

## Requirements

### Requirement: Compute available interview slots
The system SHALL compute available time slots by combining availability rules with Google Calendar free/busy data. For interview-type stages with multiple examiners, the system SHALL compute overlapping availability across eligible examiners.

#### Scenario: Available slots with no conflicts (single examiner)
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** the interviewer's Google Calendar shows no busy periods
- **THEN** the system returns 30-minute slots from 09:00 to 17:00 (minus buffer times)

#### Scenario: Available slots with calendar conflicts (single examiner)
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** the interviewer's Google Calendar shows a busy period from 10:00-11:00
- **THEN** the system returns slots that do not overlap with the busy period or its buffer zones

#### Scenario: Available slots across multiple days
- **WHEN** a user requests available slots for a date range spanning multiple days
- **THEN** the system returns slots for each day where the interviewer has availability rules defined

#### Scenario: No availability rules for a day
- **WHEN** a user requests available slots for a day where the interviewer has no availability rules
- **THEN** no slots are returned for that day

#### Scenario: Overlapping availability for multi-examiner stage
- **WHEN** a user requests available slots for an interview-type stage with `min_examiners = 3` and 4 eligible examiners
- **THEN** the system queries Google Calendar free/busy for all 4 examiners
- **AND** computes time slots where at least 3 examiners have overlapping availability
- **AND** returns only those overlapping slots

#### Scenario: No overlapping slots available
- **WHEN** the system computes overlapping availability for a multi-examiner stage and finds no slots where `min_examiners` examiners are simultaneously available
- **THEN** the system returns an empty slot list
- **AND** displays a message indicating no common availability was found

### Requirement: Reach scheduling from candidate page
The system SHALL allow recruiters to open the scheduling page for an application from the candidate detail page.

#### Scenario: Schedule Interview action on candidate page
- **WHEN** a recruiter views a candidate's application list
- **THEN** each application shows a "Schedule Interview" action
- **AND** clicking it navigates to `/app/schedule/:application_id`

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
- **AND** sends email notifications to all examiners and the candidate
- **AND** moves the application to the interview pipeline stage

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
The system SHALL allow cancelling scheduled interviews. When a multi-examiner event is cancelled, all examiners are notified.

#### Scenario: Cancel interview
- **WHEN** a user cancels a scheduled interview
- **THEN** the system updates the `interview_event` status to "cancelled"
- **AND** deletes the Google Calendar event
- **AND** sends cancellation notifications to all linked examiners
- **AND** the application remains in its current pipeline stage (does not move back)

### Requirement: Interviews dashboard
The system SHALL display upcoming interviews, showing all examiners for multi-examiner events.

#### Scenario: View upcoming interviews
- **WHEN** a user navigates to the interviews page
- **THEN** a list of upcoming interviews (status "scheduled") is displayed sorted by date
- **AND** each entry shows candidate name, job title, all examiner names, date/time, and Meet link

#### Scenario: Filter by interviewer
- **WHEN** a user filters interviews by a specific interviewer
- **THEN** only interviews where that user is one of the examiners are shown

### Requirement: Examiner substitution
The system SHALL search for a substitute examiner when a confirmed examiner cancels.

#### Scenario: Examiner cancels confirmed event
- **WHEN** an examiner cancels their participation in a confirmed multi-examiner interview event
- **THEN** the system searches for a substitute from the eligible examiner pool for that stage
- **AND** filters for examiners with overlapping availability in the same time slot
- **AND** if a substitute is found, replaces the cancelled examiner and notifies the substitute

#### Scenario: No substitute available
- **WHEN** the system cannot find a substitute examiner with overlapping availability
- **THEN** the system notifies the assigned advancer
- **AND** the advancer can choose to reschedule, find a manual substitute, or cancel the event
