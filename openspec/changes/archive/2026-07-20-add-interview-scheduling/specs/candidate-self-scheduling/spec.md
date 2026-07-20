## ADDED Requirements

### Requirement: Generate booking link
The system SHALL allow recruiters to generate a public scheduling link for a candidate.

#### Scenario: Generate booking token
- **WHEN** a recruiter clicks "Generate booking link" for an application
- **THEN** the system creates a `booking_tokens` record with a unique token, linked to the application and interviewer
- **AND** the token expires after 7 days
- **AND** the recruiter receives a shareable URL in the format `/:tenant_slug/schedule/:token`

### Requirement: Public booking page
The system SHALL provide a public page where candidates can select an interview slot.

#### Scenario: Candidate opens booking link
- **WHEN** a candidate navigates to a valid booking link
- **THEN** the system displays the interviewer's available slots for the next 14 days
- **AND** shows candidate name and job title for context

#### Scenario: Expired booking link
- **WHEN** a candidate navigates to an expired booking link
- **THEN** the system displays a message indicating the link has expired
- **AND** suggests contacting the recruiter for a new link

#### Scenario: Already used booking link
- **WHEN** a candidate navigates to a booking link that has already been used
- **THEN** the system displays a message indicating the link has already been used

### Requirement: Candidate selects slot
The system SHALL allow candidates to select an available time slot.

#### Scenario: Select slot and confirm
- **WHEN** a candidate selects a time slot and confirms
- **THEN** the system creates a Google Calendar event with a Google Meet link
- **AND** creates an `interview_event` record with status "scheduled"
- **AND** marks the booking token as used
- **AND** moves the application to the "Interview" pipeline stage
- **AND** displays a confirmation page with the Meet link and interview details

#### Scenario: Slot no longer available
- **WHEN** a candidate tries to book a slot that was taken
- **THEN** the system displays an error
- **AND** refreshes the available slots
