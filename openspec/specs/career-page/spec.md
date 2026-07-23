# Career Page

## Purpose

Serve a public, branded career page with job listings and an application form.

## Requirements

### Requirement: Public career page
The system SHALL serve a public career page at `/:tenant_slug/careers`.

#### Scenario: Career page loads
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** the page displays the tenant's logo, name, and open job listings

#### Scenario: Closed jobs hidden
- **WHEN** the career page loads
- **THEN** only jobs with status "open" are displayed

### Requirement: Job detail on career page
The system SHALL show job details on the career page including company branding.

#### Scenario: Click job listing
- **WHEN** a visitor clicks on a job listing
- **THEN** the full job description, salary range, company logo, company name, company description, and "Apply" button are shown

#### Scenario: Closed job detail
- **WHEN** a visitor navigates to a job detail page for a closed job
- **THEN** the page displays "This position is no longer available" with a link back to the career page

### Requirement: Application form
The system SHALL provide an application form for each job.

#### Scenario: Application form fields
- **WHEN** a visitor views the application form
- **THEN** it shows fields for: name, email, phone (optional), resume (file upload), and any custom fields marked as required

#### Scenario: Submit application
- **WHEN** a visitor submits a valid application
- **THEN** a candidate is created (or found by email)
- **AND** an application is created in the "New" stage
- **AND** the visitor sees a thank-you confirmation page

#### Scenario: Submit with missing required fields
- **WHEN** a visitor submits an application without required fields
- **THEN** the form shows validation errors

### Requirement: Thank you page
The system SHALL show a confirmation after application submission.

#### Scenario: Application submitted
- **WHEN** a visitor successfully submits an application
- **THEN** they see "Thank you for applying!" with a link back to careers
