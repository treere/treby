## MODIFIED Requirements

### Requirement: Time-in-stage metrics
The system SHALL track and display how long candidates spend in each pipeline stage over the trailing 90 days (labeled as such), computed efficiently via a single grouped query path.

#### Scenario: Average time per stage
- **WHEN** a user views analytics
- **THEN** the average time (in days) candidates spend in each stage over the last 90 days is displayed
- **AND** stages with no completed transitions show "N/A"

#### Scenario: Time-in-stage per pipeline
- **WHEN** a user selects a specific pipeline in analytics
- **THEN** the time-in-stage metrics reflect only that pipeline's data over the last 90 days

#### Scenario: Bottleneck indicator
- **WHEN** a user views time-in-stage metrics
- **THEN** stages with above-average time are visually highlighted as potential bottlenecks

## ADDED Requirements

### Requirement: Single-query stage counts
The system SHALL compute per-stage candidate counts with one grouped database query instead of one count per stage, returning identical results.

#### Scenario: Counts match grouped computation
- **WHEN** a user views stage counts for any scope (global, tenant, or pipeline)
- **THEN** the numbers equal the previous per-stage computation for the same data
