# Candidate Self-Scheduling

## Purpose

Allow candidates to book interview slots through the authenticated candidate portal.

## Requirements

### Requirement: Portal booking page
The system SHALL provide a booking page inside the authenticated candidate portal where a candidate can select an interview slot for their application.

#### Scenario: Candidate opens portal booking page
- **WHEN** a candidate with a scheduled interview stage logs into the portal and navigates to `/:tenant_slug/portal/schedule`
- **THEN** the system displays only time slots where at least `min_examiners` eligible examiners are available for the candidate's application
- **AND** shows the candidate name and job title for context
- **AND** each slot shows which examiners are available (e.g., "Available: Luca, Lorenzo")

#### Scenario: Candidate has no schedulable application
- **WHEN** a candidate logs into the portal but has no application in a schedulable interview stage
- **THEN** the booking page shows a message that there is nothing to schedule

### Requirement: Candidate selects slot
The system SHALL allow an authenticated candidate to select an available time slot. For multi-examiner events, the system creates a single event with all available examiners.

#### Scenario: Select slot and confirm (multi-examiner)
- **WHEN** a candidate selects a time slot and confirms on the portal booking page
- **THEN** the system creates a Google Calendar event with a Google Meet link
- **AND** creates an `interview_event` record with status "scheduled"
- **AND** links all available examiners for that slot to the event
- **AND** moves the application to the "Interview" pipeline stage
- **AND** displays a confirmation page with the Meet link and interview details
- **AND** notifies all examiners in-app (activity log)
- **AND** posts the confirmed details in the candidate's portal conversation

#### Scenario: Select slot and confirm (single examiner)
- **WHEN** a candidate selects a time slot and confirms for a single-examiner stage
- **THEN** the existing behavior applies (single interviewer linked to event)

#### Scenario: Slot no longer available
- **WHEN** a candidate tries to book a slot that was taken
- **THEN** the system displays an error
- **AND** refreshes the available slots