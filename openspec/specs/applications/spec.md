# Applications

## Purpose

Manage job applications linking candidates to jobs through pipeline stages.
## Requirements
### Requirement: Create application
The system SHALL create applications linking candidates to jobs. The system SHALL store an anagrafica snapshot on each application containing the contact data submitted at creation time.

#### Scenario: Application via career page
- **WHEN** a candidate submits the application form on the career page
- **THEN** an application is created linking the candidate to the job
- **AND** the application starts in the "New" pipeline stage
- **AND** the application stores an anagrafica snapshot of the submitted name, email, phone, and LinkedIn URL

#### Scenario: Manual application creation
- **WHEN** an authenticated user adds a candidate to a job via the internal UI (Add Candidate modal with job selector, Candidate profile Add to Job, or Job/Pipeline picker)
- **THEN** an application is created in the "New" stage for that job's effective pipeline
- **AND** the application stores the candidate's current master data as its anagrafica snapshot
- **AND** if the candidate already has an application for that job, the new one is flagged as duplicate

#### Scenario: CSV import application creation
- **WHEN** an application is created from a CSV import
- **THEN** the application stores the imported contact data as its anagrafica snapshot

### Requirement: Application stage tracking
The system SHALL track which pipeline stage each application is in.

#### Scenario: Application in stage
- **WHEN** an application exists
- **THEN** it has a pipeline_stage_id pointing to its current stage

### Requirement: Multiple applications per candidate
The system SHALL allow a candidate to apply to multiple jobs. The system SHALL allow a candidate to apply again to the same job, creating a separate application flagged as a duplicate.

#### Scenario: Candidate applies to two jobs
- **WHEN** a candidate applies to Job A and Job B
- **THEN** two separate applications exist, each in their own pipeline

#### Scenario: Candidate re-applies to the same job
- **WHEN** a candidate submits a new application for a job they already applied to
- **THEN** a new application is created for that job
- **AND** the new application is flagged as a duplicate of the existing application for that job
- **AND** both applications are retained

#### Scenario: Duplicate flag recomputed after merge
- **WHEN** a merge causes one candidate to hold multiple applications to the same job
- **THEN** those applications are flagged as duplicates
- **AND** none are deleted

### Requirement: Resume on application
The system SHALL store resume URL on the application record.

#### Scenario: Application with resume
- **WHEN** a candidate uploads a resume during application
- **THEN** the resume is stored in S3
- **AND** the application.resume_url points to the S3 key

### Requirement: List applications for a job
The system SHALL display all applications for a specific job.

#### Scenario: Job applications view
- **WHEN** a user views a job's pipeline
- **THEN** all applications for that job are shown with candidate name and current stage

