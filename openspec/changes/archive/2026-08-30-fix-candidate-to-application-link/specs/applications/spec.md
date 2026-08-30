## MODIFIED Requirements

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
