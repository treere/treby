# Analytics

## Purpose

Provide recruiting analytics including pipeline overview, time-to-hire, stage conversion rates, and time-in-stage metrics with pipeline filtering.

## Requirements

### Requirement: Pipeline overview
The system SHALL display candidate counts per pipeline stage for the selected pipeline(s).

#### Scenario: Pipeline count per stage
- **WHEN** a user views analytics for a specific pipeline
- **THEN** they see the number of candidates in each stage of that pipeline

#### Scenario: All pipelines overview
- **WHEN** a user selects "All pipelines" in analytics
- **THEN** they see candidate counts aggregated across all pipelines per stage type

### Requirement: Time to hire
The system SHALL calculate average time from application to hire.

#### Scenario: Time to hire metric
- **WHEN** a user views analytics
- **THEN** the average days from application date to hire date is displayed

#### Scenario: No hires yet
- **WHEN** there are no hired candidates
- **THEN** the time-to-hire metric shows "N/A"

### Requirement: Stage conversion rates
The system SHALL calculate conversion rates for the selected pipeline(s).

#### Scenario: Conversion rate for specific pipeline
- **WHEN** a user selects a specific pipeline
- **THEN** conversion rates between consecutive stages of that pipeline are shown

#### Scenario: Conversion rate for all pipelines
- **WHEN** a user selects "All pipelines"
- **THEN** conversion rates are aggregated across all pipelines by stage type

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

### Requirement: Analytics page
The system SHALL provide a dedicated analytics page with pipeline filtering.

#### Scenario: Analytics dashboard with pipeline selector
- **WHEN** a user navigates to Analytics
- **THEN** they see pipeline overview, time-to-hire, conversion rates, and time-in-stage
- **AND** a pipeline dropdown allows filtering all metrics by pipeline

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
