## MODIFIED Requirements

### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant. The system SHALL not return or list candidates that have been absorbed into another candidate by a merge.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin without selecting a job
- **THEN** a new candidate is created for the tenant with no application
- **AND** the candidate appears in the candidates list

#### Scenario: Manual candidate creation with job
- **WHEN** a user submits name, email, and selects a job in the Add Candidate modal
- **THEN** a new candidate is created (or reused via email dedup)
- **AND** an application for that job is created in the first stage
- **AND** the candidate appears in that job's pipeline

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)
- **AND** the existing candidate is an active (non-absorbed) candidate

#### Scenario: Absorbed candidate is not reused
- **WHEN** a user creates a candidate whose email matches an absorbed (merged) candidate
- **THEN** the system creates a new candidate
- **AND** the absorbed candidate remains absorbed
