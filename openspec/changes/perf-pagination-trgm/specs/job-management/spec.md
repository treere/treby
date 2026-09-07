## MODIFIED Requirements

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
- **AND** the listing returns to page 1
