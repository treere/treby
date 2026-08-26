## MODIFIED Requirements

### Requirement: View candidate profile
The system SHALL display detailed candidate information, using the candidate's master anagrafica. The system SHALL redirect absorbed candidate profiles to their primary and SHALL show the master anagrafica on the profile. The profile SHALL include a Conversations tab for in-platform messaging.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Conversations tab
- **WHEN** a user views a candidate profile
- **THEN** a "Conversations" tab is visible with a count badge showing the number of open conversations
- **AND** clicking the tab displays all conversations for this candidate

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style

#### Scenario: Absorbed profile redirects
- **WHEN** a user navigates to an absorbed candidate's profile URL
- **THEN** they are redirected to the primary candidate's profile
- **AND** a notice explains the profile was merged

#### Scenario: Profile shows master anagrafica
- **WHEN** a user views a candidate profile
- **THEN** the displayed contact information is the master anagrafica
- **AND** each application additionally shows the anagrafica submitted with that application when it differs from the master

### Requirement: Candidate custom fields
The system SHALL support custom fields on candidates.

#### Scenario: Candidate with custom fields
- **WHEN** custom fields are defined for candidates
- **THEN** they appear on the candidate profile and application form
