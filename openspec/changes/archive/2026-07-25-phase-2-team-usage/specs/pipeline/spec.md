# Pipeline (Modified)

## Changes from Main Spec

### ADDED Requirements

### Requirement: Pipeline selector on analytics
The system SHALL allow selecting which pipeline to view in analytics.

#### Scenario: Pipeline dropdown
- **WHEN** a user navigates to the analytics page
- **THEN** a dropdown shows all pipelines for the tenant plus an "All pipelines" option
- **AND** the default selection is "All pipelines"

#### Scenario: Select specific pipeline
- **WHEN** a user selects a specific pipeline from the dropdown
- **THEN** the analytics data updates to show only that pipeline's jobs and candidates

#### Scenario: Select all pipelines
- **WHEN** a user selects "All pipelines"
- **THEN** the analytics data aggregates across all pipelines

### Requirement: Time-in-stage metrics
The system SHALL track and display how long candidates spend in each pipeline stage.

#### Scenario: Average time per stage
- **WHEN** a user views analytics
- **THEN** the average time (in days) candidates spend in each stage is displayed
- **AND** stages with no completed transitions show "N/A"

#### Scenario: Time-in-stage per pipeline
- **WHEN** a user selects a specific pipeline in analytics
- **THEN** the time-in-stage metrics reflect only that pipeline's data

#### Scenario: Bottleneck indicator
- **WHEN** a user views time-in-stage metrics
- **THEN** stages with above-average time are visually highlighted as potential bottlenecks
