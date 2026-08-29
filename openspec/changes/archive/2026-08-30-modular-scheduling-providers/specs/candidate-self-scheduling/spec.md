# Candidate Self-Scheduling

## Purpose

Allow candidates to book interview slots through the authenticated candidate portal.

## MODIFIED Requirements

### Requirement: Candidate selects slot
The system SHALL allow an authenticated candidate to select an available time slot. For multi-examiner events, the system creates a single event with all available examiners.

#### Scenario: Select slot and confirm (multi-examiner)
- **WHEN** a candidate selects a time slot and confirms on the portal booking page
- **THEN** the system resolves the meeting provider (Google Meet if a required examiner is connected, otherwise Jitsi)
- **AND** if Google, creates a single Google Calendar event with all available examiners plus the candidate as attendees
- **AND** creates an `interview_event` record with status "scheduled" and the resolved meeting link
- **AND** links all available examiners for that slot to the event
- **AND** moves the application to the "Interview" pipeline stage
- **AND** displays a confirmation page with the meeting link and interview details
- **AND** notifies all examiners in-app (activity log)
- **AND** posts the confirmed details in the candidate's portal conversation

#### Scenario: Select slot and confirm (single examiner)
- **WHEN** a candidate selects a time slot and confirms for a single-examiner stage
- **THEN** the existing behavior applies (single interviewer linked to event)

#### Scenario: Slot no longer available
- **WHEN** a candidate tries to book a slot that was taken
- **THEN** the system displays an error
- **AND** refreshes the available slots