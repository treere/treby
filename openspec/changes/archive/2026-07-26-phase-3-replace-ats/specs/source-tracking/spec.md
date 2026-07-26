# Source Tracking

## Purpose

Track where candidates come from so hiring teams can understand which channels produce the best candidates and allocate sourcing effort accordingly.

## Requirements

### Requirement: Configure sources
The system SHALL allow admins to configure candidate sources per tenant.

#### Scenario: Default sources
- **WHEN** a new tenant is created
- **THEN** the following default sources are available: LinkedIn, Referral, Indeed, Company Website, Other

#### Scenario: Add custom source
- **WHEN** an admin adds a custom source
- **THEN** the source is added to the tenant's source list

#### Scenario: Edit source
- **WHEN** an admin renames a source
- **THEN** all applications tagged with that source are updated

#### Scenario: Delete source
- **WHEN** an admin deletes a source that has applications
- **THEN** the applications are re-tagged as "Other"

#### Scenario: Source settings page
- **WHEN** an admin navigates to Settings → Sources
- **THEN** they see the list of sources with edit/delete actions and an add button

### Requirement: Tag applications with source
The system SHALL record the source on each application.

#### Scenario: Source on public application
- **WHEN** a candidate applies via the public career page
- **THEN** the application form includes an optional "How did you hear about us?" dropdown
- **AND** the selected source is saved with the application

#### Scenario: Source on CSV import
- **WHEN** a user imports candidates via CSV
- **THEN** they can select a source to tag all imported applications

#### Scenario: Source on manual creation
- **WHEN** a recruiter manually creates a candidate and adds them to a pipeline
- **THEN** they can optionally select a source

#### Scenario: No source selected
- **WHEN** no source is provided during application creation
- **THEN** the source defaults to "Other"

### Requirement: Display source on candidate/application
The system SHALL show the source on candidate and application views.

#### Scenario: Source on candidate profile
- **WHEN** a user views a candidate profile
- **THEN** each application shows its source

#### Scenario: Source on pipeline card
- **WHEN** a user views the pipeline board
- **THEN** candidate cards show the source (if space permits, or on hover)

### Requirement: Source analytics
The system SHALL display source breakdown in analytics.

#### Scenario: Source breakdown chart
- **WHEN** a user views analytics
- **THEN** a chart shows the number of applications per source

#### Scenario: Source breakdown per pipeline
- **WHEN** a user selects a specific pipeline in analytics
- **THEN** the source breakdown reflects only that pipeline's applications

#### Scenario: Source conversion rates
- **WHEN** a user views analytics
- **THEN** the chart shows not just application counts but also how many candidates from each source reached the "Interview" and "Hired" stages
