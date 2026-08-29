# application-review Delta

## MODIFIED Requirements

### Requirement: Review indicator on pipeline cards
The system SHALL show a visual indicator for unreviewed applications on pipeline cards and on job-page candidate cards.

#### Scenario: New application badge on pipeline board
- **WHEN** a candidate has an application with `reviewed = false`
- **AND** a user views the pipeline Kanban board
- **THEN** a "NEW" badge is shown on their card

#### Scenario: New application badge on job page
- **WHEN** a candidate has an application with `reviewed = false`
- **AND** a user views the job detail page
- **THEN** a "NEW" badge is shown on their candidate card

#### Scenario: Reviewed application
- **WHEN** a candidate has an application with `reviewed = true`
- **THEN** no badge is shown on their card

### Requirement: Toggle review state
The system SHALL allow marking applications as reviewed or unreviewed with a single click from the pipeline board or the job page.

#### Scenario: Mark as reviewed from pipeline card
- **WHEN** a user clicks the review toggle on a pipeline card
- **THEN** the application's `reviewed` field is set to `true`
- **AND** the "NEW" badge disappears

#### Scenario: Mark as unreviewed from pipeline card
- **WHEN** a user clicks the review toggle on a reviewed pipeline card
- **THEN** the application's `reviewed` field is set to `false`
- **AND** the "NEW" badge reappears

#### Scenario: Mark as reviewed from job page
- **WHEN** a user clicks the review toggle on an unreviewed job-page card
- **THEN** the application's `reviewed` field is set to `true`
- **AND** the "NEW" badge disappears

#### Scenario: Mark as unreviewed from job page
- **WHEN** a user clicks the review toggle on a reviewed job-page card
- **THEN** the application's `reviewed` field is set to `false`
- **AND** the "NEW" badge reappears