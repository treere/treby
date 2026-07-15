# Applications

## Purpose

Manage job applications linking candidates to jobs through pipeline stages.

## Requirements

### Requirement: Create application
The system SHALL create applications linking candidates to jobs.

#### Scenario: Application via career page
- **WHEN** a candidate submits the application form on the career page
- **THEN** an application is created linking the candidate to the job
- **AND** the application starts in the "New" pipeline stage

#### Scenario: Manual application creation
- **WHEN** an authenticated user adds a candidate to a job
- **THEN** an application is created in the "New" stage

### Requirement: Application stage tracking
The system SHALL track which pipeline stage each application is in.

#### Scenario: Application in stage
- **WHEN** an application exists
- **THEN** it has a pipeline_stage_id pointing to its current stage

### Requirement: Multiple applications per candidate
The system SHALL allow a candidate to apply to multiple jobs.

#### Scenario: Candidate applies to two jobs
- **WHEN** a candidate applies to Job A and Job B
- **THEN** two separate applications exist, each in their own pipeline

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
