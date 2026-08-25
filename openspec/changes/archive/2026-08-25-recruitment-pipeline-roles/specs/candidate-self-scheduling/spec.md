# Candidate Self-Scheduling (delta)

## MODIFIED Requirements

### Requirement: Public booking page
The system SHALL provide a public page where candidates can select an interview slot. For multi-examiner stages, only slots with sufficient examiner availability are shown.

#### Scenario: Candidate opens booking link
- **WHEN** a candidate navigates to a valid booking link for a multi-examiner stage
- **THEN** the system displays only time slots where at least `min_examiners` eligible examiners are available
- **AND** shows candidate name and job title for context
- **AND** each slot shows which examiners are available (e.g., "Available: Luca, Lorenzo")

#### Scenario: Candidate opens booking link (single examiner)
- **WHEN** a candidate navigates to a valid booking link for a single-examiner stage
- **THEN** the system displays the single examiner's available slots (existing behavior)

#### Scenario: Expired booking link
- **WHEN** a candidate navigates to an expired booking link
- **THEN** the system displays a message indicating the link has expired
- **AND** suggests contacting the recruiter for a new link

#### Scenario: Already used booking link
- **WHEN** a candidate navigates to a booking link that has already been used
- **THEN** the system displays a message indicating the link has already been used

### Requirement: Candidate selects slot
The system SHALL allow candidates to select an available time slot. For multi-examiner events, the system creates a single event with all available examiners.

#### Scenario: Select slot and confirm (multi-examiner)
- **WHEN** a candidate selects a time slot and confirms for a multi-examiner stage
- **THEN** the system creates a Google Calendar event with a Google Meet link
- **AND** creates an `interview_event` record with status "scheduled"
- **AND** links all available examiners for that slot to the event
- **AND** marks the booking token as used
- **AND** moves the application to the "Interview" pipeline stage
- **AND** displays a confirmation page with the Meet link and interview details

#### Scenario: Select slot and confirm (single examiner)
- **WHEN** a candidate selects a time slot and confirms for a single-examiner stage
- **THEN** the existing behavior applies (single interviewer linked to event)

#### Scenario: Slot no longer available
- **WHEN** a candidate tries to book a slot that was taken
- **THEN** the system displays an error
- **AND** refreshes the available slots

### Requirement: Generate booking link
The system SHALL allow recruiters to generate a public scheduling link for a candidate. For multi-examiner stages, the booking token links to the stage's examiner pool.

#### Scenario: Generate booking token
- **WHEN** a recruiter clicks "Generate booking link" for an application in a multi-examiner stage
- **THEN** the system creates a `booking_tokens` record with a unique token, linked to the application and the pipeline stage (not a single interviewer)
- **AND** the token expires after 7 days
- **AND** the recruiter receives a shareable URL

#### Scenario: Generate booking token (single examiner)
- **WHEN** a recruiter clicks "Generate booking link" for an application in a single-examiner stage
- **THEN** the existing behavior applies (token linked to application and single interviewer)
