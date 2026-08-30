## ADDED Requirements

### Requirement: Job view tracking hook
The system SHALL count a view when a visitor loads an open job's public detail page, respecting tenant scoping, deduplication, and bot/internal filtering.

#### Scenario: Public job detail triggers tracking
- **WHEN** a visitor navigates to `/:tenant_slug/careers/:job_id` where the job exists and `status == "open"`
- **THEN** the system attempts to record a `job_view` (via `Treby.JobViews.track_view`) with deduplication (60-minute window per session_hash+job) and without blocking the page render; if the view is deduplicated, filtered as bot, or from a team member of that tenant, no record is created but the page still renders normally

#### Scenario: View tracking fails closed
- **WHEN** the tracking insertion fails (DB error, etc.)
- **THEN** the public page still renders successfully and the error is logged as warning without exposing anything to the visitor

#### Scenario: Tracking respects visibility
- **WHEN** a job has `visible == false` but `status == "open"` and a visitor loads it via direct link
- **THEN** the view is still tracked (direct link is a valid discovery path)
