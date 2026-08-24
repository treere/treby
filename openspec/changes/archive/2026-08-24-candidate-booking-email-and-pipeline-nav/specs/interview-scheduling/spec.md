# Interview Scheduling

## Delta

### ADDED Requirements

### Requirement: Reach scheduling from candidate page
The system SHALL allow recruiters to open the scheduling page for an application from the candidate detail page.

#### Scenario: Schedule Interview action on candidate page
- **WHEN** a recruiter views a candidate's application list
- **THEN** each application shows a "Schedule Interview" action
- **AND** clicking it navigates to `/app/schedule/:application_id`

### MODIFIED Requirements

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
- **AND** sends a confirmation email to the candidate with the Meet link, interviewer name, and interview details
- **AND** moves the application to the "Interview" pipeline stage

#### Scenario: Slot no longer available
- **WHEN** a recruiter tries to book a slot that was taken by another user
- **THEN** the system returns an error indicating the slot is no longer available
- **AND** refreshes the available slots list
