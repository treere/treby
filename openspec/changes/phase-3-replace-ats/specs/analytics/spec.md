# Analytics (Modified)

## Changes from Main Spec

### ADDED Requirements

### Requirement: Source breakdown
The system SHALL display a breakdown of applications by source.

#### Scenario: Source chart
- **WHEN** a user views analytics
- **THEN** a chart shows the number of applications per source

#### Scenario: Source chart per pipeline
- **WHEN** a user selects a specific pipeline
- **THEN** the source breakdown reflects only that pipeline's applications

#### Scenario: Source conversion funnel
- **WHEN** a user views analytics
- **THEN** the source chart also shows how many candidates from each source reached "Interview" and "Hired" stages
