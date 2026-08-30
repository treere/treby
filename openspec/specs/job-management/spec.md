# Job Management

## Purpose

Manage job postings including creation, editing, listing, and closing with optional salary ranges.

## Requirements

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

### Requirement: Edit job posting
The system SHALL allow authenticated users to edit job postings.

#### Scenario: Successful job edit
- **WHEN** a user updates a job's title, description, or salary range
- **THEN** the job is updated with the new values

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
The system SHALL provide navigation from the job detail page to the pipeline board and a way to copy the public link.

#### Scenario: Access pipeline from job detail
- **WHEN** a user views a job's detail page
- **THEN** a "View Pipeline" link/button is visible that navigates to the pipeline board for that job

#### Scenario: Copy public link from job detail
- **WHEN** a user views a job's detail page
- **THEN** a "Copy Public Link" button is visible
- **AND** clicking it copies the public URL to the clipboard

### Requirement: Job salary range
The system SHALL support optional salary range on job postings.

#### Scenario: Job with salary range
- **WHEN** a user creates a job with salary range "$100k-$150k"
- **THEN** the salary range is displayed on the job listing

#### Scenario: Job without salary range
- **WHEN** a user creates a job without salary range
- **THEN** the salary range field is null and not displayed

### Requirement: Analytics navigation from job detail
The system SHALL expose navigation from a job's internal detail page to its per-job analytics page.

#### Scenario: Analytics link visible on job detail
- **WHEN** an authenticated team member views the job detail page at `/app/jobs/:id`
- **THEN** an "Analytics" link/button (with chart/bar icon) is visible in the header actions area alongside "Copy Public Link", "Edit", and "View Pipeline"
- **AND** clicking it navigates to `/app/jobs/:id/analytics`

#### Scenario: Job list shows view indicators
- **WHEN** a team member views the job listing page at `/app/jobs`
- **THEN** each job row displays synthetic view metrics: total views and views in last 7 days (e.g., "123 views · 12 in last 7 days"), or a muted "No views yet" if the job has zero views
- **AND** the indicators are scoped to the current tenant (no cross-tenant leakage)

#### Scenario: Job detail header shows view summary
- **WHEN** a team member views the job detail page at `/app/jobs/:id`
- **THEN** a summary badge near the title shows total views and last-7-days views for that job (or "No views yet"), consistent with the analytics page KPIs
