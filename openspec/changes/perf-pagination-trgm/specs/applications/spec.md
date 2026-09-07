## MODIFIED Requirements

### Requirement: List applications for a job
The system SHALL display applications for a specific job in pages of 25 (configurable default) instead of all rows at once.

#### Scenario: Job applications view
- **WHEN** a user views a job's pipeline
- **THEN** the first 25 applications for that job are shown with candidate name and current stage
- **AND** a pager navigates the remaining applications
