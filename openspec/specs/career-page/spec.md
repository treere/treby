# Career Page

## Purpose

Serve a public, branded career page with job listings and an application form.

## Requirements

### Requirement: Public career page
The system SHALL serve a public career page at `/:tenant_slug/careers`. The page SHALL include a consistent public header that contains a brand/homepage link (navigates to `/`) on the left and the theme toggle plus language switcher on the right, rendered with `dark:` overrides so the header remains ≥4.5:1 in dark mode. The header SHALL be visible regardless of theme or locale.

#### Scenario: Career page loads
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** the page displays the tenant's logo, name, and open job listings

#### Scenario: Closed jobs hidden
- **WHEN** the career page loads
- **THEN** only jobs with status "open" are displayed

### Requirement: Job detail on career page
The system SHALL show job details on the career page including company branding. The detail surface at `/:tenant_slug/careers/:job_id` SHALL include the same public header (homepage link + theme + language) as the listing page, and the "Back to all positions" link and any fallback ghost buttons SHALL have `dark:` overrides to remain legible in dark mode and SHALL be wrapped with `gettext` so they translate correctly (no English/Italian mix).

#### Scenario: Click job listing
- **WHEN** a visitor clicks on a job listing
- **THEN** the full job description, salary range, company logo, company name, company description, and "Apply" button are shown

#### Scenario: Closed job detail
- **WHEN** a visitor navigates to a job detail page for a closed job
- **THEN** the page displays "This position is no longer available" with a link back to the career page


#### Scenario: Job detail header and back link in dark Italian
- **WHEN** a visitor with locale IT opens `http://localhost:4000/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da` in dark mode
- **THEN** the header with homepage/brand + theme + language is visible and contrast-compliant, the "← Back to all positions" link is shown in Italian ("← Torna a tutte le posizioni" or the `msgstr` for that `msgid`) with `dark:text-*` contrast, and no English/Italian mix appears


### Requirement: Application form
The system SHALL provide an application form for each job. Upon submission, the system SHALL create a welcome conversation so the candidate can track and discuss their application in the portal.

#### Scenario: Application form fields
- **WHEN** a visitor views the application form
- **THEN** it shows fields for: name, email, phone (optional), resume (file upload), and any custom fields marked as required

#### Scenario: Submit application
- **WHEN** a visitor submits a valid application
- **THEN** a candidate is created (or found by email)
- **AND** an application is created in the "New" stage
- **AND** the visitor sees a thank-you confirmation page
- **AND** if the `new_application_candidate` notification is enabled, a short confirmation ping email is sent to the candidate

#### Scenario: Submit application with portal
- **WHEN** a visitor submits a valid application
- **THEN** a conversation is created with context "general" and a system message "Your application for {job_title} has been received"
- **AND** the confirmation ping email contains a "View Your Application" button linking to `/:tenant_slug/portal`

#### Scenario: Submit with missing required fields
- **WHEN** a visitor submits an application without required fields
- **THEN** the form shows validation errors

### Requirement: Thank you page
The system SHALL show a confirmation after application submission.

#### Scenario: Application submitted
- **WHEN** a visitor successfully submits an application
- **THEN** they see "Thank you for applying!" with a link back to careers

#### Scenario: Application submitted with portal
- **WHEN** a visitor successfully submits an application
- **THEN** the thank-you page includes a note: "You can track your application status in the candidate portal" with a link to `/:tenant_slug/portal`

### Requirement: Duplicate application feedback
The system SHALL inform the candidate if they have already applied to the same job.

#### Scenario: Submit duplicate application
- **WHEN** a candidate submits an application for a job they have already applied to (same email normalized, same job)
- **THEN** the system does not create a duplicate application
- **AND** the UI shows "You have already applied to this position on {date}" with a link to `/:tenant_slug/portal` and to "View other positions"
- **AND** it does not show a generic "Thank you" as if it were a new submission

#### Scenario: Submit new application
- **WHEN** a candidate submits for a job they have not applied to before
- **THEN** a new application is created and the thank-you confirmation is shown as before

### Requirement: Structured job metadata on career page
The system SHALL display structured job metadata (location, employment type, workplace type, published date) on career pages when present.

#### Scenario: Job detail shows structured meta
- **WHEN** a visitor views a job with `location`, `employment_type`, or `workplace_type` set
- **THEN** the detail page shows those values alongside salary and published date, with empty fields hidden

#### Scenario: Job listings show structured meta
- **WHEN** a visitor views `/:tenant_slug/careers` or `/careers`
- **THEN** each job card shows location and badge pills for employment/workplace type when present

#### Scenario: Search includes location
- **WHEN** a visitor searches on the career page with a query matching a job's location
- **THEN** that job appears in the results

### Requirement: Guided multi-apply
The system SHALL guide candidates applying to multiple positions with prefill and applied-state awareness.

#### Scenario: Prefilled apply form for authenticated candidate
- **WHEN** a candidate who is logged into the portal for that tenant visits `/:tenant_slug/careers/:job_id/apply`
- **THEN** the form fields `name`, `email`, and `phone` are prefilled from the candidate's profile and remain editable, with a hint "Prefilled from your portal profile"

#### Scenario: Applied badge on tenant career page
- **WHEN** an authenticated candidate for tenant `acme` visits `/acme/careers`
- **THEN** each job they have already applied to shows an "Applied ✓" badge

#### Scenario: Job detail shows already-applied CTA
- **WHEN** an authenticated candidate who has already applied to that job views `/:tenant_slug/careers/:job_id`
- **THEN** the "Apply Now" button is replaced with "Already applied — View status" linking to `/:tenant_slug/portal`

### Requirement: Public career page content
The company description shown at the top of the public career page is authored as plain Markdown in Settings → Brand and rendered as sanitized HTML (headings, lists, links, emphasis). The textarea carries a short hint that Markdown is supported.

#### Scenario: Markdown company description
- **WHEN** a company description contains Markdown (e.g. a list or a link)
- **THEN** the career page top shows it rendered (list bullets, clickable link)
- **AND** any raw HTML/script content is stripped
