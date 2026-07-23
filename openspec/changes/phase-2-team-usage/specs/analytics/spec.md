# Analytics (Modified)

## Changes from Main Spec

### MODIFIED Requirements

### Requirement: Pipeline overview
The system SHALL display candidate counts per pipeline stage for the selected pipeline(s).

#### Scenario: Pipeline count per stage
- **WHEN** a user views analytics for a specific pipeline
- **THEN** they see the number of candidates in each stage of that pipeline

#### Scenario: All pipelines overview
- **WHEN** a user selects "All pipelines" in analytics
- **THEN** they see candidate counts aggregated across all pipelines per stage type

### Requirement: Stage conversion rates
The system SHALL calculate conversion rates for the selected pipeline(s).

#### Scenario: Conversion rate for specific pipeline
- **WHEN** a user selects a specific pipeline
- **THEN** conversion rates between consecutive stages of that pipeline are shown

#### Scenario: Conversion rate for all pipelines
- **WHEN** a user selects "All pipelines"
- **THEN** conversion rates are aggregated across all pipelines by stage type

### Requirement: Analytics page
The system SHALL provide a dedicated analytics page with pipeline filtering.

#### Scenario: Analytics dashboard with pipeline selector
- **WHEN** a user navigates to Analytics
- **THEN** they see pipeline overview, time-to-hire, conversion rates, and time-in-stage
- **AND** a pipeline dropdown allows filtering all metrics by pipeline
