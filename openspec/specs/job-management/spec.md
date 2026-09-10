# Job Management

## Purpose

Manage job postings including creation, editing, listing, and closing with optional salary ranges.
## Requirements
### Requirement: Create job posting
The system SHALL allow authenticated users to create job postings via a dedicated creation page (`/app/jobs/new` and `/:tenant_slug/app/jobs/new`) with a live public preview and explicit publication controls. The system SHALL associate the job with the user's tenant and handle empty pipeline selection gracefully. The job listing page SHALL NOT host an inline creation form; its "New Job" action SHALL navigate to the creation page.

#### Scenario: Successful job creation via dedicated page
- **WHEN** a user navigates to the creation page, fills title, description, and optional fields (salary range, location, employment/workplace types, pipeline, custom fields), sets status and visibility, and submits
- **THEN** a new job is created with the chosen `status` (`open`/`closed`) and `visible` (`true`/`false`) and associated with the user's tenant
- **AND** the user is redirected to the job detail page with a success flash

#### Scenario: Job creation with default pipeline
- **WHEN** a user opens the creation page
- **THEN** the pipeline selector shows only existing pipelines with the tenant's default pipeline preselected
- **AND** when the job is created without changing the selection, the job is created with that default pipeline's id

#### Scenario: Missing required fields on creation page
- **WHEN** a user submits a job without title or description on the creation page
- **THEN** the system returns inline validation errors and no job is created

#### Scenario: Creation page shows live public preview
- **WHEN** a user edits fields on the creation page
- **THEN** the preview pane updates to show the job as it will appear publicly (Markdown-rendered description, location, employment/workplace badges, salary, company context) without persisting

#### Scenario: Publication defaults on creation
- **WHEN** a user opens the creation page
- **THEN** status defaults to `open` and visibility defaults to `public`
- **AND** toggling status to `closed` disables the visibility control with hint "Closed jobs are private and hidden from public boards." and the server treats `visible` as `false` regardless of the submitted value

#### Scenario: Public closed job is coerced to private
- **WHEN** a user submits a job with `visible=true` and `status=closed` (bypassing the disabled control)
- **THEN** the server coerces `visible` to `false` and creates the job as `closed`/`private`; direct context calls with `visible=true` + `closed` without coercion fail validation with "cannot be visible when the job is closed"

#### Scenario: New Job navigates from listing
- **WHEN** a user clicks "New Job" on the job listing
- **THEN** the system navigates to the dedicated creation page

### Requirement: Edit job posting
The system SHALL allow authenticated users to edit job postings.

#### Scenario: Successful job edit
- **WHEN** a user updates a job's title, description, or salary range
- **THEN** the job is updated with the new values

### Requirement: List jobs
The system SHALL display jobs for the current tenant in pages of 25 (configurable default) instead of all rows at once.

#### Scenario: Job listing page
- **WHEN** a user navigates to the jobs page
- **THEN** the first 25 jobs for their tenant are displayed with title, status, and salary range
- **AND** clicking a job title navigates to the job detail page
- **AND** a pager shows the result count and navigation controls

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

### Requirement: Structured job fields
The system SHALL support optional structured fields for location and employment details on job postings.

#### Scenario: Create job with structured fields
- **WHEN** a team member creates a job with `location`, `employment_type`, and `workplace_type`
- **THEN** the job is persisted with those values
- **AND** invalid enum values are rejected with a validation error

#### Scenario: Create job without structured fields
- **WHEN** a team member creates a job providing only `title` and `description`
- **THEN** the job is created successfully with structured fields defaulting to `nil`

#### Scenario: Edit job structured fields
- **WHEN** a team member updates `location` or type fields on an existing job
- **THEN** the changes are persisted and visible on the next load

### Requirement: Time-ordered job ids
Job primary keys SHALL be time-ordered UUIDv7, so that for rows created after the switch, descending id order reflects reverse insertion order.

#### Scenario: Same-timestamp jobs order by id
- **WHEN** two jobs share the same `inserted_at` timestamp
- **THEN** the job list orders them by descending id (newest first)

#### Scenario: Existing ids remain valid
- **WHEN** records created before the switch (random UUIDv4) are listed
- **THEN** they appear and remain addressable with no migration or data change

### Requirement: Visible requires open status
A job posting SHALL NOT be markable visible while its status is closed; attempting to set `visible=true` on a closed job SHALL fail changeset validation.

#### Scenario: Publish a closed job
- **WHEN** a user sets visible on a job whose status is closed
- **THEN** validation fails with an error on visibility

#### Scenario: Open job stays publishable
- **WHEN** a user sets visible on a job whose status is open
- **THEN** validation passes

### Requirement: Job description authoring
The system SHALL allow authoring job descriptions as plain Markdown in a regular textarea with a short hint that Markdown is supported. No toolbar or preview is offered.

#### Scenario: Author job in Markdown
- **WHEN** an admin writes `**bold**` or a `- list` in the job description
- **THEN** the text is stored as-is and rendered as HTML wherever displayed

