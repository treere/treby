# Candidate Management

## Delta

## ADDED Requirements

### Requirement: Reject candidate from profile
The system SHALL allow rejecting a candidate from the candidate profile page by moving their application to the stage with `stage_type = "rejected"` in the application's effective pipeline.

#### Scenario: Reject candidate with application
- **WHEN** a user clicks "Reject" on a candidate profile with at least one application and confirms with a motivation
- **THEN** the application is moved to the stage with `stage_type = "rejected"` in the application's effective pipeline
- **AND** a rejection conversation message is created

#### Scenario: Reject candidate without application
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** the system displays an error message explaining the candidate has no application to reject