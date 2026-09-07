# Candidate Management

## Purpose

Manage candidate profiles within a multi-tenant recruiting system.
## Requirements
### Requirement: Create candidate
The system SHALL allow creating candidates with contact information. The system SHALL associate the candidate with the user's tenant. The system SHALL not return or list candidates that have been absorbed into another candidate by a merge.

#### Scenario: Manual candidate creation
- **WHEN** a user submits name, email, and optional phone/linkedin without selecting a job
- **THEN** a new candidate is created for the tenant with no application
- **AND** the candidate appears in the candidates list

#### Scenario: Manual candidate creation with job
- **WHEN** a user submits name, email, and selects a job in the Add Candidate modal
- **THEN** a new candidate is created (or reused via email dedup)
- **AND** an application for that job is created in the first stage
- **AND** the candidate appears in that job's pipeline

#### Scenario: Duplicate email detection
- **WHEN** a user tries to create a candidate with an existing email in the same tenant
- **THEN** the system returns the existing candidate (upsert behavior)
- **AND** the existing candidate is an active (non-absorbed) candidate

#### Scenario: Absorbed candidate is not reused
- **WHEN** a user creates a candidate whose email matches an absorbed (merged) candidate
- **THEN** the system creates a new candidate
- **AND** the absorbed candidate remains absorbed

### Requirement: List candidates
The system SHALL display candidates for the current tenant in pages of 25 (configurable default) instead of all rows at once. Search and job/stage filters SHALL combine with pagination and reset to page 1 on change.

#### Scenario: Candidate listing page
- **WHEN** a user navigates to the candidates page
- **THEN** the first 25 candidates for their tenant are displayed with name, email, and application count
- **AND** a pager shows the result count and navigation controls

#### Scenario: Pager navigation
- **WHEN** a user clicks a page number or Next/Prev in the pager
- **THEN** that page of candidates is shown
- **AND** the URL updates with `?page=N` so the page is deep-linkable

#### Scenario: Filter resets pagination
- **WHEN** a user changes search text or job/stage filters
- **THEN** the listing returns to page 1

### Requirement: View candidate profile
The system SHALL display detailed candidate information, using the candidate's master anagrafica. The system SHALL redirect absorbed candidate profiles to their primary and SHALL show the master anagrafica on the profile. The system SHALL load the candidate profile without crashing regardless of whether the candidate has interviews, and SHALL correctly preload interview examiners.

#### Scenario: Candidate profile page
- **WHEN** a user clicks on a candidate
- **THEN** the profile shows name, email, phone, LinkedIn URL, all applications, and notes

#### Scenario: Scheduled interviews on profile
- **WHEN** a user views a candidate profile
- **THEN** the profile shows a "Scheduled Interviews" section
- **AND** each interview shows date/time, interviewer name, status, and Google Meet link
- **AND** cancelled interviews are shown with a strikethrough style

#### Scenario: Profile with interviews does not crash
- **WHEN** a user navigates to a candidate profile that has at least one scheduled interview with an examiner
- **THEN** the page returns 200 without raising an Ecto association error
- **AND** the "Scheduled Interviews" section lists the interview with the examiner name

#### Scenario: Absorbed profile redirects
- **WHEN** a user navigates to an absorbed candidate's profile URL
- **THEN** they are redirected to the primary candidate's profile
- **AND** a notice explains the profile was merged

#### Scenario: Profile shows master anagrafica
- **WHEN** a user views a candidate profile
- **THEN** the displayed contact information is the master anagrafica
- **AND** each application additionally shows the anagrafica submitted with that application when it differs from the master

### Requirement: Search and filter candidates
The system SHALL allow searching and filtering candidates.

#### Scenario: Search candidates by name or email
- **WHEN** a user types in the search input on the candidates page
- **THEN** candidates whose name or email contains the search term (case-insensitive) are displayed

#### Scenario: Filter candidates by job
- **WHEN** a user selects a job from the filter dropdown
- **THEN** only candidates with an application for that job are shown

#### Scenario: Filter candidates by stage
- **WHEN** a user selects a pipeline stage from the filter dropdown
- **THEN** only candidates with an application in that stage are shown

#### Scenario: Combined search and filters
- **WHEN** a user applies search text and filters simultaneously
- **THEN** only candidates matching ALL criteria are shown

### Requirement: Edit candidate profile
The system SHALL allow editing candidate information from the candidate profile page.

#### Scenario: Inline edit on candidate profile
- **WHEN** a user clicks "Edit" on the candidate profile page
- **THEN** an inline form appears with name, email, phone, LinkedIn URL, and custom fields pre-populated

#### Scenario: Save candidate edit
- **WHEN** a user submits the edit form with valid data
- **THEN** the candidate record is updated and an activity log entry is created

#### Scenario: Candidate edit validation
- **WHEN** a user submits invalid data (missing required fields, duplicate email)
- **THEN** validation errors are shown and the form remains open

### Requirement: Candidate custom fields
The system SHALL support custom fields on candidates.

#### Scenario: Candidate with custom fields
- **WHEN** custom fields are defined for candidates
- **THEN** they appear on the candidate profile and application form

### Requirement: Reject candidate from profile
The system SHALL allow rejecting a candidate from the candidate profile page by moving their application to the stage with `stage_type = "rejected"` in the application's effective pipeline.

#### Scenario: Reject candidate with application
- **WHEN** a user clicks "Reject" on a candidate profile with at least one application and confirms with a motivation
- **THEN** the application is moved to the stage with `stage_type = "rejected"` in the application's effective pipeline
- **AND** a rejection conversation message is created

#### Scenario: Reject candidate without application
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** the system displays an error message explaining the candidate has no application to reject

### Requirement: Profile portal actions without applications
The system SHALL allow using the candidate profile's portal actions (send message, request info, reject) for candidates with no applications without crashing the page.

#### Scenario: Request info for candidate without applications
- **WHEN** a user clicks "Request Info" and confirms on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application
- **AND** no conversation is created

#### Scenario: Reject candidate without applications
- **WHEN** a user confirms rejection on a candidate profile with no applications
- **THEN** the page does not crash
- **AND** a clear error message is displayed explaining the candidate has no application

#### Scenario: New message for candidate without applications
- **WHEN** a user sends a new portal message to a candidate with no applications
- **THEN** the message is created without an application reference
- **AND** no error is raised

### Requirement: Candidates context facade and query centralization
The system SHALL provide candidate business logic through a delegating facade `Treby.Candidates` that forwards listing/search/filter to `Candidates.Queries` and merge/undo to `Candidates.Merge`, with no inline `import Ecto.Query` inside functions and with `stringify_keys` centralized in `Treby.Helpers.Map`. Tenant isolation and search/filter behavior SHALL remain identical.

#### Scenario: Facade preserves public API
- **WHEN** existing code calls `Treby.Candidates.list_candidates/2` or `Treby.Candidates.merge_candidates/3`
- **THEN** the call succeeds via `defdelegate` to `Candidates.Queries` or `Candidates.Merge` without requiring call-site changes

#### Scenario: Query helpers centralized
- **WHEN** `list_candidates/2` is invoked with `search`, `job_id`, or `stage_id` filters
- **THEN** results match pre-refactor behavior because `apply_search`, `apply_job_filter`, and `apply_stage_filter` are defined once in `Candidates.Queries` and reused

#### Scenario: Shared helper deduplication
- **WHEN** candidate creation or application creation stringifies attribute keys
- **THEN** both paths use `Treby.Helpers.Map.stringify_keys/1` and no duplicate `defp stringify_keys` remains in `candidates.ex` or `pipeline.ex`

### Requirement: Concurrent duplicate-email safety
The system SHALL guarantee that concurrent candidate creations with the same tenant and email produce a single active candidate. A partial unique index on active candidates SHALL back the application-level upsert.

#### Scenario: Concurrent creates return one candidate
- **WHEN** two requests create a candidate with the same tenant and email at the same time
- **THEN** exactly one active candidate exists afterwards
- **AND** both requests return `{:ok, candidate}` for that same record

#### Scenario: Merged candidates do not block reuse
- **WHEN** the only matching email belongs to an absorbed (merged) candidate
- **THEN** creation succeeds with a new candidate (tombstoned rows are excluded from uniqueness)

### Requirement: Indexed search
Candidate name/email search SHALL remain case-insensitive contains matching and SHALL be served by trigram (GIN) indexes so leading-wildcard queries avoid sequential scans.

#### Scenario: Search uses trigram index
- **WHEN** a user searches candidates with any term (including `%` or partial words)
- **THEN** results match the previous `ilike` semantics
- **AND** the query plan uses the trigram index instead of a sequential scan

### Requirement: Time-ordered candidate ids
Candidate primary keys SHALL be time-ordered UUIDv7, so that for rows created after the switch, descending id order reflects reverse insertion order.

#### Scenario: Same-timestamp candidates order by id
- **WHEN** two candidates share the same `inserted_at` timestamp
- **THEN** the candidate list orders them by descending id (newest first)

#### Scenario: Existing ids remain valid
- **WHEN** records created before the switch (random UUIDv4) are listed
- **THEN** they appear and remain addressable with no migration or data change

