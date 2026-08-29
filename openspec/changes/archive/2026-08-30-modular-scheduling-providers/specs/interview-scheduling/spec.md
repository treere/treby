# Interview Scheduling

## Purpose

Enable recruiters and candidates to schedule interviews with availability computation, calendar integration, and notifications.

## MODIFIED Requirements

### Requirement: Compute available interview slots
The system SHALL compute available time slots by combining availability rules with busy periods from the internal calendar and every connected external calendar provider. For interview-type stages with multiple examiners, the system SHALL compute overlapping availability across eligible examiners. When a connected external provider returns an error, slot computation SHALL fail closed.

#### Scenario: Available slots with no conflicts (single examiner)
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** neither the internal calendar nor any connected provider reports busy periods
- **THEN** the system returns 30-minute slots from 09:00 to 17:00 (minus buffer times)

#### Scenario: Available slots with calendar conflicts (single examiner)
- **WHEN** a user requests available slots for an interviewer on a day they have 09:00-17:00 availability
- **AND** the internal calendar or a connected provider reports a busy period from 10:00-11:00
- **THEN** the system returns slots that do not overlap with the busy period or its buffer zones

#### Scenario: Existing interview blocks a slot
- **WHEN** the interviewer already has a scheduled interview at 10:00-10:30 on Treby and availability is requested for that day
- **THEN** the 10:00-10:30 slot is not returned, regardless of external calendar connections

#### Scenario: Available slots across multiple days
- **WHEN** a user requests available slots for a date range spanning multiple days
- **THEN** the system returns slots for each day where the interviewer has availability rules defined

#### Scenario: No availability rules for a day
- **WHEN** a user requests available slots for a day where the interviewer has no availability rules
- **THEN** no slots are returned for that day

#### Scenario: Overlapping availability for multi-examiner stage
- **WHEN** a user requests available slots for an interview-type stage with `min_examiners = 3` and 4 eligible examiners
- **THEN** the system computes busy periods from the internal calendar and all connected providers for all 4 examiners
- **AND** returns time slots where at least 3 examiners have overlapping availability

#### Scenario: No overlapping slots available
- **WHEN** the system computes overlapping availability for a multi-examiner stage and finds no slots where `min_examiners` examiners are simultaneously available
- **THEN** the system returns an empty slot list
- **AND** displays a message indicating no common availability was found

#### Scenario: Connected provider errors
- **WHEN** a connected external provider returns an error during busy aggregation
- **THEN** the slot computation returns an error
- **AND** no slots are displayed

### Requirement: Schedule interview as recruiter
The system SHALL allow recruiters to schedule interviews from the application page, supporting multi-examiner events.

#### Scenario: Initiate scheduling
- **WHEN** a recruiter clicks "Schedule Interview" on an application page
- **THEN** the system displays a scheduling form with date picker and available slots
- **AND** for interview-type stages, the form shows slots computed from overlapping examiner availability

#### Scenario: Select slot and confirm (multi-examiner)
- **WHEN** a recruiter selects an available slot for a multi-examiner stage and confirms
- **THEN** the system resolves the meeting provider (Google Meet if a required examiner is connected, otherwise Jitsi)
- **AND** if Google, creates a single Google Calendar event with all examiners plus the candidate as attendees
- **AND** creates an `interview_event` record with status "scheduled" and the resolved meeting link
- **AND** links all eligible examiners for that slot to the event
- **AND** notifies all examiners in-app (activity log)
- **AND** posts an interview message in the candidate's portal conversation with the date, time, interviewer, and meeting link
- **AND** moves the application to the interview pipeline stage

#### Scenario: Slot no longer available
- **WHEN** a recruiter tries to book a slot that was taken by another user
- **THEN** the system returns an error indicating the slot is no longer available
- **AND** refreshes the available slots list

### Requirement: Interview notifications
The system SHALL notify candidates and examiners about scheduled interviews without sending full-content emails to the candidate.

#### Scenario: Candidate notification
- **WHEN** an interview is scheduled for a candidate
- **THEN** the system posts a message in the candidate's portal conversation with the interview date/time, meeting link, and interviewer name
- **AND** if the candidate's `interview_update` preference is enabled, sends a short ping email: "There's an update regarding your interview for {job_title}" with a "View in Portal" button linking to `/:tenant_slug/portal`

#### Scenario: Interviewer notification
- **WHEN** an interview is scheduled with an interviewer
- **THEN** the system logs an in-app activity event with the interview date/time, candidate name, and meeting link
- **AND** no email is sent to the interviewer

### Requirement: Cancel interview
The system SHALL allow cancelling scheduled interviews. When a multi-examiner event is cancelled, all examiners are notified.

#### Scenario: Cancel interview
- **WHEN** a user cancels a scheduled interview
- **THEN** the system updates the `interview_event` status to "cancelled"
- **AND** if an external calendar event exists, deletes it using the calendar owner's connection and `provider_event_id`
- **AND** sends cancellation notifications to all linked examiners
- **AND** the application remains in its current pipeline stage (does not move back)

### Requirement: Interviews dashboard
The system SHALL display upcoming interviews, showing all examiners for multi-examiner events.

#### Scenario: View upcoming interviews
- **WHEN** a user navigates to the interviews page
- **THEN** a list of upcoming interviews (status "scheduled") is displayed sorted by date
- **AND** each entry shows candidate name, job title, all examiner names, date/time, and meeting link

#### Scenario: Filter by interviewer
- **WHEN** a user filters interviews by a specific interviewer
- **THEN** only interviews where that user is one of the examiners are shown

## REMOVED Requirements

### Requirement: Google Meet event creation
**Reason**: Superseded by provider-agnostic meeting creation. Meeting links are now resolved automatically between Google Meet and Jitsi via the `meeting-providers` capability, and the single-event-with-all-examiners behavior lives in the scheduling requirements above.
**Migration**: Booking flows resolve the meeting provider automatically. Interviews booked before this change keep their stored `video_conf_url`.