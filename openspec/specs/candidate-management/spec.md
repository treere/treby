# Candidate Management

## Purpose

Manage candidate profiles within a multi-tenant recruiting system.

## Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin
- **THEN** a new candidate is created for the tenant

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)

### Requirement: List candidates
The system SHALL display all candidates for the current tenant.

#### Scenario: Candidate listing page
- **WHEN** a user navigates to the candidates page
- **THEN** all candidates for their tenant are displayed with name, email, and application count

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

### Requirement: Candidate custom fields
The system SHALL support custom fields on candidates.

#### Scenario: Candidate with custom fields
- **WHEN** custom fields are defined for candidates
- **THEN** they appear on the candidate profile and application form
