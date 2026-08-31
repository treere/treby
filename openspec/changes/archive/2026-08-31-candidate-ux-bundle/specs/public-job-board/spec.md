## MODIFIED Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions across all tenants.

#### Scenario: Global board loads
- **WHEN** a visitor navigates to `/careers`
- **THEN** the page displays all open jobs with `visible=true` from all tenants

#### Scenario: Each job shows company info
- **WHEN** the global board loads
- **THEN** each job listing shows the company logo, company name, job title, and salary range

#### Scenario: No visible jobs
- **WHEN** there are no visible open positions across any tenant
- **THEN** the page displays "No open positions available"

### Requirement: Per-job visibility
The system SHALL allow controlling whether individual jobs appear on public boards via a `visible` flag.

#### Scenario: Visible job appears in listing
- **WHEN** a job has `status=open` and `visible=true`
- **THEN** it appears in the public job board listing

#### Scenario: Non-visible job hidden from listing
- **WHEN** a job has `status=open` and `visible=false`
- **THEN** it does NOT appear in any public board listing

#### Scenario: Non-visible job accessible via direct link
- **WHEN** a visitor navigates directly to `/:tenant_slug/careers/:job_id` for a non-visible open job
- **THEN** the job detail page loads normally

#### Scenario: Closed job not accessible
- **WHEN** a visitor navigates to `/:tenant_slug/careers/:job_id` for a closed job
- **THEN** the page displays "This position is no longer available"

### Requirement: Copy public link
The system SHALL provide a way to copy the public job URL from the internal job detail page.

#### Scenario: Copy link button exists
- **WHEN** a user views the internal job detail page (`/app/jobs/:id`)
- **THEN** a "Copy Public Link" button is visible

#### Scenario: Copy link action
- **WHEN** a user clicks "Copy Public Link"
- **THEN** the full absolute public URL (`https://<host>/:tenant_slug/careers/:job_id`) is copied to the clipboard, including the hostname
- **AND** a confirmation message is shown

### Requirement: Visibility toggle in job listing
The system SHALL show a visibility toggle for each job in the internal job listing.

#### Scenario: Toggle visible
- **WHEN** a user toggles visibility for an open job from private to public
- **THEN** the job appears on the public board

#### Scenario: Toggle hidden
- **WHEN** a user toggles visibility for an open job from public to private
- **THEN** the job is removed from the public board listing

#### Scenario: Closed job toggle disabled
- **WHEN** a job has `status=closed`
- **THEN** the visibility toggle is disabled

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

### Requirement: Public board shows structured job metadata
The system SHALL display structured job metadata on public boards.

#### Scenario: Listings show location and type badges
- **WHEN** the global board or tenant board loads
- **THEN** each job listing shows location and badge pills for employment/workplace type when present, alongside company and salary info

### Requirement: Applied badge for multi-apply
The system SHALL indicate on public boards which positions an authenticated candidate has already applied to.

#### Scenario: Badge on global board
- **WHEN** an authenticated candidate for tenant `acme` visits `/careers`
- **THEN** only jobs belonging to `acme` that they have applied to show the "Applied ✓" badge; jobs from other tenants do not

#### Scenario: Anonymous visitor sees no badge
- **WHEN** an anonymous visitor views `/careers` or `/:tenant_slug/careers`
- **THEN** no applied badges are shown

#### Scenario: Prefill on global board apply
- **WHEN** an authenticated candidate navigates from a global board listing to `/:tenant_slug/careers/:job_id/apply`
- **THEN** the apply form is prefilled as per tenant match

### Requirement: Candidate apply post-submit guidance and help contact
The system SHALL show human, candidate-friendly post-apply guidance and a configurable help/contact block on the public apply flow that is visible only when a contact email is configured.

#### Scenario: Help contact visible on apply when email configured
- **WHEN** a candidate views `/:tenant_slug/careers/:job_id/apply` and `tenant.settings["support_email"]` (or `["contact_email"]`) is present
- **THEN** the page shows a "Need help?" block (`id="candidate-help"`) with `Contact <company> support or email us at <email>` alongside the form

#### Scenario: Help contact hidden when no email configured
- **WHEN** a candidate views `/:tenant_slug/careers/:job_id/apply` and no `support_email`/`contact_email` is configured in `tenant.settings`
- **THEN** the "Need help?" block is not rendered and no hard-coded `support@treby.app` fallback is shown

#### Scenario: Thank-you shows next steps including spam and expiry
- **WHEN** a candidate successfully submits an application at `/:tenant_slug/careers/:job_id/apply`
- **THEN** the thank-you state shows "Check your email — including spam — for a 10-minute code to track your application" and a primary link labeled "Track your application" to `/:tenant_slug/portal/login` (not generic "Access Your Portal")

#### Scenario: Thank-you help visibility follows same rule
- **WHEN** the thank-you state is shown and a contact email is configured
- **THEN** the same "Need help?" block remains visible with the configured email
- **WHEN** no contact email is configured
- **THEN** no help block is shown on the thank-you state either
