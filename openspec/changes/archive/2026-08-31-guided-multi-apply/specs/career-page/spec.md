## MODIFIED Requirements

### Requirement: Application form
The system SHALL provide an application form for each job with optional prefill for authenticated candidates.

#### Scenario: Authenticated candidate views apply form
- **WHEN** a candidate who is logged into the portal for that tenant visits `/:tenant_slug/careers/:job_id/apply`
- **THEN** the form fields `name`, `email`, and `phone` are prefilled from the candidate's profile
- **AND** the fields remain editable

#### Scenario: Anonymous candidate views apply form
- **WHEN** an anonymous visitor views the apply form
- **THEN** the form fields are empty as before

#### Scenario: Job detail shows applied state
- **WHEN** an authenticated candidate who has already applied to that job views `/:tenant_slug/careers/:job_id`
- **THEN** the "Apply Now" button is replaced with "Already applied — View status" linking to `/:tenant_slug/portal`
