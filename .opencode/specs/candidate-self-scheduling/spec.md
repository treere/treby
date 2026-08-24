# Candidate Self-Scheduling

## Purpose

Allow recruiters to email a candidate a self-scheduling booking link.

## Requirements

### Requirement: Email booking link to candidate
The system SHALL allow recruiters to email a candidate a self-scheduling booking link.

#### Scenario: Email booking link from scheduling page
- **WHEN** a recruiter clicks "Email booking link" on the scheduling page for an application
- **THEN** the system generates a booking token linked to the application
- **AND** emails the candidate a link in the format `/:tenant_slug/schedule/:token`

#### Scenario: Candidate receives booking link email
- **WHEN** a candidate receives the booking link email
- **THEN** the email explains they can choose their own interview time slot
- **AND** the booking link opens the public booking page with available slots
