# Candidate Booking Email

## Purpose

Send candidates an email containing a self-scheduling booking link so they can book their own interview slot.

## Requirements

### Requirement: Email booking link to candidate
The system SHALL send a candidate an email containing a self-scheduling booking link for their application.

#### Scenario: Recruiter emails booking link
- **WHEN** a recruiter clicks "Email booking link" on the scheduling page for an application
- **THEN** the system generates a booking token for that application
- **AND** sends an email to the candidate's email address
- **AND** the email contains a booking link in the format `/:tenant_slug/schedule/:token`

#### Scenario: Email requires an interviewer
- **WHEN** a recruiter clicks "Email booking link" but no interviewer is selected
- **THEN** the system still generates a booking link without an interviewer
- **AND** the candidate can still book through the link

#### Scenario: Booking link is valid for 7 days
- **WHEN** the booking link email is sent
- **THEN** the embedded booking token expires after 7 days from creation

#### Scenario: Email sends confirmation to recruiter
- **WHEN** the booking link email is sent successfully
- **THEN** the system shows a success message to the recruiter
- **AND** the candidate is informed they can choose their own time slot