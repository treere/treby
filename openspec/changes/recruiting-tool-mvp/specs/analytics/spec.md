## ADDED Requirements

### Requirement: Pipeline overview
The system SHALL display candidate counts per pipeline stage for each job.

#### Scenario: Pipeline count per stage
- **WHEN** a user views analytics for a job
- **THEN** they see the number of candidates in each pipeline stage

### Requirement: Time to hire
The system SHALL calculate average time from application to hire.

#### Scenario: Time to hire metric
- **WHEN** a user views analytics
- **THEN** the average days from application date to hire date is displayed

#### Scenario: No hires yet
- **WHEN** there are no hired candidates
- **THEN** the time-to-hire metric shows "N/A"

### Requirement: Stage conversion rates
The system SHALL calculate what percentage of candidates move from one stage to the next.

#### Scenario: Conversion rate display
- **WHEN** a user views analytics
- **THEN** conversion rates between consecutive stages are shown (e.g., "Screen → Phone: 60%")

### Requirement: Analytics page
The system SHALL provide a dedicated analytics page.

#### Scenario: Analytics dashboard
- **WHEN** a user navigates to Analytics
- **THEN** they see pipeline overview, time-to-hire, and conversion rates for all jobs
