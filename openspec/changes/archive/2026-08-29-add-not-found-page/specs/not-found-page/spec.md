# Not Found Page

## ADDED Requirements

### Requirement: Not Found page exists at a dedicated route
The system SHALL provide a "Not Found" page served at the `/404` route, rendering a friendly, on-brand page instead of a stacktrace.

#### Scenario: Direct visit to the 404 route
- **WHEN** a user navigates to `/404`
- **THEN** a styled "Not Found" page is displayed
- **AND** no stacktrace or exception details are shown

#### Scenario: Not Found page includes a way back
- **WHEN** a user views the Not Found page
- **THEN** a visible link/button is provided to return to a relevant section of the app (e.g. the job/candidate list or home)

### Requirement: Non-existent app entity redirects to Not Found
The authenticated app SHALL redirect to the Not Found page when an entity-detail LiveView is mounted for a record that does not exist.

#### Scenario: Non-existent job detail
- **WHEN** a logged-in user opens `/app/jobs/<uuid>` for a job that does not exist
- **THEN** the user is redirected to the Not Found page
- **AND** no stacktrace is rendered

#### Scenario: Non-existent candidate detail
- **WHEN** a logged-in user opens `/app/candidates/<uuid>` for a candidate that does not exist
- **THEN** the user is redirected to the Not Found page
- **AND** no stacktrace is rendered

#### Scenario: Non-existent application in schedule
- **WHEN** a logged-in user opens `/app/schedule/<uuid>` for an application that does not exist
- **THEN** the user is redirected to the Not Found page
- **AND** no stacktrace is rendered

#### Scenario: Non-existent job in pipeline
- **WHEN** a logged-in user opens `/app/pipeline/<job-uuid>` for a job that does not exist
- **THEN** the user is redirected to the Not Found page
- **AND** no stacktrace is rendered

### Requirement: Non-existent settings entity redirects to Not Found
The settings sub-views SHALL redirect to the Not Found page when an entity referenced in the URL (e.g. a pipeline, custom field, or pipeline stage) does not exist.

#### Scenario: Non-existent pipeline settings
- **WHEN** an admin opens `/app/settings/pipeline/<uuid>` for a pipeline that does not exist
- **THEN** the user is redirected to the Not Found page
- **AND** no stacktrace is rendered

### Requirement: Non-existent public entity redirects to Not Found
Public career/portal routes SHALL redirect to the Not Found page when their referenced entity does not exist, instead of rendering a stacktrace.

#### Scenario: Non-existent public job
- **WHEN** a visitor opens `/<tenant>/careers/<job-uuid>` or `/<tenant>/careers/<job-uuid>/apply` for a job that does not exist
- **THEN** the visitor is redirected to the Not Found page
- **AND** no stacktrace is rendered

### Requirement: Existing entities are unaffected
Entity-detail routes for existing records SHALL continue to render normally with no behavior change.

#### Scenario: Existing job detail loads
- **WHEN** a logged-in user opens `/app/jobs/<uuid>` for an existing job
- **THEN** the job detail page renders as before
- **AND** no redirect to the Not Found page occurs
