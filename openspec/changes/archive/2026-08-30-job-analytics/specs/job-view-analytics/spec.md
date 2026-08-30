## ADDED Requirements

### Requirement: Track job page views
The system SHALL record a view event each time a visitor loads the public job detail page (`/:tenant_slug/careers/:job_id`) for an open job, subject to deduplication and filtering rules.

#### Scenario: Public visitor view is tracked
- **WHEN** an anonymous visitor (or candidate/guest) loads an open job's public detail page
- **THEN** a `job_view` record is created with `job_id`, `tenant_id`, `viewed_at` (now), `session_hash` (anonymous), `referer` domain if present, `utm_source` if present in query, and truncated `user_agent`

#### Scenario: Deduplication within window suppresses duplicate
- **WHEN** the same session (same `session_hash`) loads the same job again within 60 minutes
- **THEN** no new `job_view` record is created (the second load is ignored)

#### Scenario: View after window is counted again
- **WHEN** the same session loads the same job after more than 60 minutes from the last counted view
- **THEN** a new `job_view` record is created

#### Scenario: Team member visit is not tracked
- **WHEN** an authenticated team user whose `tenant_id` matches the job's `tenant_id` loads the public job page (e.g., to test the listing)
- **THEN** no `job_view` record is created

#### Scenario: Bot User-Agent is not tracked
- **WHEN** a request has a User-Agent matching `bot|crawl|spider|slurp|mediapartners` (case-insensitive)
- **THEN** no `job_view` record is created

#### Scenario: Closed job view is not tracked
- **WHEN** a visitor loads the public page for a job with `status == "closed"`
- **THEN** no `job_view` record is created (the page shows "position no longer available")

#### Scenario: Multi-tenant isolation
- **WHEN** a view is recorded for `job_id` belonging to tenant A
- **THEN** it is stored with `tenant_id == A` and never appears in analytics queries for tenant B

### Requirement: Per-job view aggregates
The system SHALL provide aggregated view metrics for a given job scoped to its tenant.

#### Scenario: Total and unique views
- **WHEN** a recruiter requests summary for a job
- **THEN** the system returns `total_views` (count of `job_views` rows) and `unique_views` (count distinct `session_hash`)

#### Scenario: Rolling window counts
- **WHEN** a recruiter requests summary for a job
- **THEN** the system returns `views_last_7_days`, `views_last_30_days`, `views_last_90_days` counted from `viewed_at >= now - N days`

#### Scenario: Zero views returns zeros
- **WHEN** a job has no `job_views` rows
- **THEN** all counts are `0` and breakdowns return empty arrays (no error)

#### Scenario: Tenant isolation on aggregates
- **WHEN** tenant B queries aggregates for a job belonging to tenant A (by guessing job_id)
- **THEN** the system returns `{:error, :not_found}` (or empty) and does not leak counts

### Requirement: Daily and monthly frequency breakdowns
The system SHALL provide time-series breakdowns of views per job for trend analysis.

#### Scenario: Daily breakdown last 30 days
- **WHEN** a recruiter views daily frequency for a job
- **THEN** the system returns an array of 30 entries `{date, count}` for each calendar day in last 30 days (days with 0 views included as `0`), ordered ascending by date

#### Scenario: Monthly breakdown last 12 months
- **WHEN** a recruiter views monthly frequency for a job
- **THEN** the system returns an array of 12 entries `{month, count}` for each month in last 12 months (months with 0 views included as `0`), ordered ascending

#### Scenario: Average daily views
- **WHEN** a recruiter views aggregates for a job that has views
- **THEN** the system returns `avg_daily_views` computed as `total_views / days_since_first_view` (or `total_views / 30` for last 30 days window, clearly labeled)

### Requirement: View-to-application funnel
The system SHALL compute the conversion from views to applications for a given job.

#### Scenario: Funnel metrics present
- **WHEN** a recruiter views funnel for a job
- **THEN** the system returns `total_views`, `total_applications` (count of applications where `job_id == job.id`), and `conversion_rate` = `applications / views * 100` rounded to 1 decimal (0.0% if views == 0)

#### Scenario: Comparison to tenant average
- **WHEN** a recruiter views funnel for a job
- **THEN** the system also returns `tenant_avg_conversion_rate` (average conversion across all open jobs of that tenant) for contextual comparison, or `nil` if tenant has no views

### Requirement: Traffic source breakdown
The system SHALL break down views by traffic source when available.

#### Scenario: Source breakdown by utm_source and referer
- **WHEN** a recruiter views source breakdown for a job
- **THEN** the system groups views by `utm_source` if present, otherwise by `referer` domain, otherwise as `"Direct"`, returning an array `{source, count, percentage}` ordered descending by count

#### Scenario: No source data
- **WHEN** all views for a job have no `utm_source` and no `referer`
- **THEN** source breakdown returns a single entry `{source: "Direct", count: total_views, percentage: 100}`

### Requirement: Per-job analytics page
The system SHALL provide a dedicated analytics page for each job, accessible from the job management area.

#### Scenario: Navigate to analytics from job detail
- **WHEN** an authenticated team member views the job detail page (`/app/jobs/:id`)
- **THEN** a link/button labeled "Analytics" (with chart icon) is visible and navigates to `/app/jobs/:id/analytics`

#### Scenario: Analytics page content
- **WHEN** a team member navigates to `/app/jobs/:id/analytics`
- **THEN** they see: job title header with back link to job detail, KPI cards (total views, unique views, views last 7/30 days, avg daily, conversion rate), a daily bar chart (last 30 days), a monthly table/bar for last 12 months, a source breakdown table/bar, and the view→application funnel with tenant average

#### Scenario: Analytics page for job with no views
- **WHEN** a team member views analytics for a job with zero views
- **THEN** KPI cards show `0`/`N/A`, charts show empty state message "No views yet", and funnel shows `0%` with explanatory text

#### Scenario: Unauthorized access
- **WHEN** a user from tenant B navigates to `/app/jobs/:id/analytics` where `:id` belongs to tenant A
- **THEN** the system redirects to `/404` (or shows not found) and does not reveal job existence

#### Scenario: Closed job analytics still accessible
- **WHEN** a job has been closed
- **THEN** its analytics page remains accessible and shows historical views (no new views are tracked after closing)

### Requirement: Synthetic indicators in job management
The system SHALL show synthetic view indicators in the job list and job detail header for quick scanning.

#### Scenario: Job list shows view counts
- **WHEN** a team member views the job listing page (`/app/jobs`)
- **THEN** each job row shows `total_views` and `views_last_7_days` (e.g., "123 views · 12 last 7d") or "No views yet" if zero

#### Scenario: Job detail shows summary badge
- **WHEN** a team member views the job detail page (`/app/jobs/:id`)
- **THEN** the header area near title/actions shows a badge with `total_views` and `views_last_7_days`

### Requirement: Privacy and data minimization
The system SHALL minimize personal data in stored view events.

#### Scenario: No raw IP stored
- **WHEN** a view is recorded
- **THEN** the raw IP address is never persisted; only an anonymized `session_hash` derived from IP+User-Agent+salt is stored

#### Scenario: User-Agent truncation
- **WHEN** a view is recorded with a long User-Agent
- **THEN** `user_agent` is truncated to at most 255 characters before storage

#### Scenario: Referer stored as domain
- **WHEN** a view is recorded with a referer header
- **THEN** the stored `referer` is the domain/host part (or full URL truncated) and `utm_source` is extracted separately from query params; no full referer path with PII is required
