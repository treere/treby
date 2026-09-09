## MODIFIED Requirements

### Requirement: Pipeline overview
The system SHALL display candidate counts per pipeline stage for the selected pipeline(s) as a horizontal bar chart rendered via Contex.

#### Scenario: Pipeline count per stage
- **WHEN** a user views analytics for a specific pipeline
- **THEN** they see the number of candidates in each stage of that pipeline as a Contex `BarChart` with `orientation: :horizontal`, ordered by stage position, with stage colors applied via `colour_palette` and value labels on bars

#### Scenario: All pipelines overview
- **WHEN** a user selects "All pipelines" in analytics
- **THEN** they see candidate counts aggregated across all pipelines per stage type as a horizontal Contex `BarChart`

#### Scenario: Empty pipeline overview occupies space
- **WHEN** there are no candidates in any stage
- **THEN** the Pipeline Overview card keeps `min-h-[320px]` and shows a centered dashed placeholder with icon and text ("No pipeline data — add candidates to see the chart") instead of collapsing

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
The system SHALL track and display how long candidates spend in each pipeline stage over the trailing 90 days (labeled as such), computed efficiently via a single grouped query path, as a horizontal bar chart.

#### Scenario: Average time per stage
- **WHEN** a user views analytics
- **THEN** the average time (in days) candidates spend in each stage over the last 90 days is displayed as a Contex `BarChart` horizontal with `avg_days` on the value axis and bottleneck stages visually distinguished

#### Scenario: Time-in-stage per pipeline
- **WHEN** a user selects a specific pipeline in analytics
- **THEN** the time-in-stage metrics reflect only that pipeline's data over the last 90 days as a Contex chart

#### Scenario: Bottleneck indicator
- **WHEN** a user views time-in-stage metrics
- **THEN** stages with above-average time are visually highlighted as potential bottlenecks in the chart (distinct color or badge)

#### Scenario: Empty time-in-stage occupies space
- **WHEN** there is no time-in-stage data for the trailing 90 days
- **THEN** the card keeps `min-h-[320px]` and shows a centered placeholder instead of collapsing or showing an empty list

### Requirement: Analytics page
The system SHALL provide a dedicated analytics page with pipeline filtering where visualizations are SVG charts.

#### Scenario: Analytics dashboard with pipeline selector
- **WHEN** a user navigates to Analytics
- **THEN** they see pipeline overview (Contex horizontal bar), time-to-hire, conversion rates, and time-in-stage (Contex horizontal bar)
- **AND** a pipeline dropdown allows filtering all metrics by pipeline and all charts re-render server-side

### Requirement: Tenant-isolated analytics

The system SHALL scope all analytics queries by tenant_id so one tenant cannot see another tenant's candidates.

#### Scenario: All pipelines view is tenant-scoped

- **WHEN** a user views Analytics with "All pipelines" selected
- **THEN** Total Candidates, pipeline counts, avg time to hire, conversion rates reflect only that tenant's data

#### Scenario: Two tenants isolated

- **WHEN** tenant A has 2 candidates and tenant B has 3 candidates
- **THEN** tenant A's analytics shows 2 total candidates and tenant B shows 3, not 5


### Requirement: Single-query stage counts
The system SHALL compute per-stage candidate counts with one grouped database query instead of one count per stage, returning identical results.

#### Scenario: Counts match grouped computation
- **WHEN** a user views stage counts for any scope (global, tenant, or pipeline)
- **THEN** the numbers equal the previous per-stage computation for the same data
