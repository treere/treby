## MODIFIED Requirements

### Requirement: Job detail page actions
The system SHALL provide navigation from the job detail page to the pipeline board and a way to copy the public link.

#### Scenario: Access pipeline from job detail
- **WHEN** a user views a job's detail page
- **THEN** a "View Pipeline" link/button is visible that navigates to the pipeline board for that job

#### Scenario: Copy public link from job detail
- **WHEN** a user views a job's detail page
- **THEN** a "Copy Public Link" button is visible
- **AND** clicking it copies the public URL to the clipboard
