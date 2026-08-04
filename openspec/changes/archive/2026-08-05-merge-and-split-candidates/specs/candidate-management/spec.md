# Candidate Management

## Delta for merge-and-split-candidates

## MODIFIED Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant. The system SHALL not return or list candidates that have been absorbed into another candidate by a merge.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin
- **THEN** a new candidate is created for the tenant

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)
- **AND** the existing candidate is an active (non-absorbed) candidate

#### Scenario: Absorbed candidate is not reused
- **WHEN** a user creates a candidate whose email matches an absorbed (merged) candidate
- **THEN** the system creates a new candidate
- **AND** the absorbed candidate remains absorbed

### Requirement: View candidate profile
The system SHALL display detailed candidate information, using the candidate's master anagrafica. The system SHALL redirect absorbed candidate profiles to their primary and SHALL show the master anagrafica on the profile.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

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
