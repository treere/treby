# Candidate Management

## Delta

## ADDED Requirements

### Requirement: Profile portal actions without applications
The system SHALL allow using the candidate profile's portal actions (send message, request info, reject) for candidates with no applications without crashing the page.

#### Scenario: Request info for candidate without applications
- **WHEN** a user clicks "Request Info" and confirms on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application
- **AND** no conversation is created

#### Scenario: Reject candidate without applications
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application

#### Scenario: New message for candidate without applications
- **WHEN** a user sends a new portal message to a candidate with no applications
- **THEN** the message is created without an application reference
- **AND** no error is raised