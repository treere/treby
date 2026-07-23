# Public Job Board

## Purpose

Serve a global public job board and control per-job visibility on public boards.

## Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions across all tenants.

#### Scenario: Global board loads
- **WHEN** a visitor navigates to `/careers`
- **THEN** the page displays all open jobs with `visible=true` from all tenants

#### Scenario: Each job shows company info
- **WHEN** the global board loads
- **THEN** each job listing shows the company logo, company name, job title, and salary range

#### Scenario: No visible jobs
- **WHEN** there are no visible open positions across any tenant
- **THEN** the page displays "No open positions available"

### Requirement: Per-job visibility
The system SHALL allow controlling whether individual jobs appear on public boards via a `visible` flag.

#### Scenario: Visible job appears in listing
- **WHEN** a job has `status=open` and `visible=true`
- **THEN** it appears in the public job board listing

#### Scenario: Non-visible job hidden from listing
- **WHEN** a job has `status=open` and `visible=false`
- **THEN** it does NOT appear in any public board listing

#### Scenario: Non-visible job accessible via direct link
- **WHEN** a visitor navigates directly to `/:tenant_slug/careers/:job_id` for a non-visible open job
- **THEN** the job detail page loads normally

#### Scenario: Closed job not accessible
- **WHEN** a visitor navigates to `/:tenant_slug/careers/:job_id` for a closed job
- **THEN** the page displays "This position is no longer available"

### Requirement: Copy public link
The system SHALL provide a way to copy the public job URL from the internal job detail page.

#### Scenario: Copy link button exists
- **WHEN** a user views the internal job detail page (`/app/jobs/:id`)
- **THEN** a "Copy Public Link" button is visible

#### Scenario: Copy link action
- **WHEN** a user clicks "Copy Public Link"
- **THEN** the public URL (`/:tenant_slug/careers/:job_id`) is copied to the clipboard
- **AND** a confirmation message is shown

### Requirement: Visibility toggle in job listing
The system SHALL show a visibility toggle for each job in the internal job listing.

#### Scenario: Toggle visible
- **WHEN** a user toggles visibility for an open job from private to public
- **THEN** the job appears on the public board

#### Scenario: Toggle hidden
- **WHEN** a user toggles visibility for an open job from public to private
- **THEN** the job is removed from the public board listing

#### Scenario: Closed job toggle disabled
- **WHEN** a job has `status=closed`
- **THEN** the visibility toggle is disabled
