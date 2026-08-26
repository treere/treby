## MODIFIED Requirements

### Requirement: Application form
The system SHALL provide an application form for each job. Upon submission, when the candidate portal is enabled, the system SHALL create a welcome conversation and send a portal access email.

#### Scenario: Application form fields
- **WHEN** a visitor views the application form
- **THEN** it shows fields for: name, email, phone (optional), resume (file upload), and any custom fields marked as required

#### Scenario: Submit application
- **WHEN** a visitor submits a valid application
- **THEN** a candidate is created (or found by email)
- **AND** an application is created in the "New" stage
- **AND** the visitor sees a thank-you confirmation page
- **AND** a confirmation email is sent to the candidate (if enabled)
- **AND** team alert emails are sent to admins/job owner (if enabled)

#### Scenario: Submit application with portal enabled
- **WHEN** a visitor submits a valid application
- **AND** the tenant has the candidate portal enabled
- **THEN** a conversation is created with context "general" and a system message "Your application for {job_title} has been received"
- **AND** the confirmation email contains a "View Your Application" button linking to the portal
- **AND** a magic link email is sent so the candidate can access the portal

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
- **AND** the tenant has the candidate portal enabled
- **THEN** the thank-you page includes a note: "You can track your application status in the candidate portal" with a link to `/:tenant_slug/portal`
