## MODIFIED Requirements

### Requirement: Create job posting
The system SHALL allow authenticated users to create job postings. The system SHALL associate the job with the user's tenant and handle empty pipeline selection gracefully.

#### Scenario: Successful job creation
- **WHEN** a user submits title, description, and optional salary range
- **THEN** a new job is created with status "open"
- **AND** the job is associated with the user's tenant

#### Scenario: Job creation with default pipeline
- **WHEN** a user opens the new job form
- **THEN** the pipeline selector shows only existing pipelines with the tenant's default pipeline preselected
- **AND** when the job is created without changing the selection, the job is created with that default pipeline's id

#### Scenario: Missing required fields
- **WHEN** a user submits a job without title or description
- **THEN** the system returns validation errors
