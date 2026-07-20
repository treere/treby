## MODIFIED Requirements

### Requirement: View candidate profile
The system SHALL display detailed candidate information.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style
