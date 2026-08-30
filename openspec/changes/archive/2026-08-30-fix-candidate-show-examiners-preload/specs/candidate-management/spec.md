## MODIFIED Requirements

### Requirement: View candidate profile
The system SHALL display detailed candidate information, using the candidate's master anagrafica. The system SHALL redirect absorbed candidate profiles to their primary and SHALL show the master anagrafica on the profile. The system SHALL load the candidate profile without crashing regardless of whether the candidate has interviews, and SHALL correctly preload interview examiners.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style

#### Scenario: Profile with interviews does not crash
- **WHEN** a user navigates to a candidate profile that has at least one scheduled interview with an examiner
- **THEN** the page returns 200 without raising an Ecto association error
- **AND** the "Scheduled Interviews" section lists the interview with the examiner name

#### Scenario: Absorbed profile redirects
- **WHEN** a user navigates to an absorbed candidate's profile URL
- **THEN** they are redirected to the primary candidate's profile
- **AND** a notice explains the profile was merged

#### Scenario: Profile shows master anagrafica
- **WHEN** a user views a candidate profile
- **THEN** the displayed contact information is the master anagrafica
- **AND** each application additionally shows the anagrafica submitted with that application when it differs from the master
