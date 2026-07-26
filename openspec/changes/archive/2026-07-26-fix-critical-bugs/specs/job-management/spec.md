## MODIFIED Requirements

### Requirement: Create job posting
The system SHALL allow authenticated users to create job postings. The system SHALL associate the job with the user's tenant and handle empty pipeline selection gracefully.

#### Scenario: Successful job creation
- **WHEN** a user submits title, description, and optional salary range
- **THEN** a new job is created with status "open"
- **AND** the job is associated with the user's tenant

#### Scenario: Job creation with default pipeline
- **WHEN** a user submits a job with the "Default pipeline" prompt selected (empty pipeline_id)
- **THEN** the job is created without a specific pipeline association (pipeline_id is nil)
- **AND** the job is associated with the user's tenant

#### Scenario: Missing required fields
- **WHEN** a user submits a job without title or description
- **THEN** the system returns validation errors
