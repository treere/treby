## MODIFIED Requirements

### Requirement: List jobs
The system SHALL display all jobs for the current tenant.

#### Scenario: Job listing page
- **WHEN** a user navigates to the jobs page
- **THEN** all jobs for their tenant are displayed with title, status, and salary range
- **AND** clicking a job title navigates to the job detail page

#### Scenario: Filter by status
- **WHEN** a user filters jobs by status (open/closed)
- **THEN** only jobs matching that status are shown

### Requirement: Close job posting
The system SHALL allow users to close job postings.

#### Scenario: Close a job
- **WHEN** a user closes a job
- **THEN** the job status changes to "closed"
- **AND** the job is hidden from the public career page

### Requirement: Job detail page actions
The system SHALL provide navigation from the job detail page to the pipeline board.

#### Scenario: Access pipeline from job detail
- **WHEN** a user views a job's detail page
- **THEN** a "View Pipeline" link/button is visible that navigates to the pipeline board for that job
