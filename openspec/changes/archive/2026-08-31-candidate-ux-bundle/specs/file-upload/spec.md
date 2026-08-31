## MODIFIED Requirements

### Requirement: Resume upload
The system SHALL allow uploading resumes as part of the application process and SHALL surface visible feedback and rejection messaging for candidate uploads.

#### Scenario: Upload resume file
- **WHEN** a candidate selects a file for resume upload
- **THEN** the file is validated (size ≤ 10MB, type: pdf/doc/docx) and the UI immediately shows the filename and size, live progress while uploading, and a success state; on completion the file is uploaded to S3 under `/{tenant_id}/resumes/{candidate_id}/{filename}`

#### Scenario: Resume too large
- **WHEN** a candidate uploads a file larger than 10MB
- **THEN** the system shows an inline error "File is too large (max 10MB)" next to the upload field and blocks submit until the file is removed or replaced

#### Scenario: Resume wrong type (e.g., JPG photo)
- **WHEN** a candidate picks a file with extension not in pdf/doc/docx (e.g., jpg/png)
- **THEN** the system shows an inline error "File type not accepted (use PDF, DOC, or DOCX). If you have a photo, convert to PDF or contact support." and the file is not uploaded

#### Scenario: Upload in progress blocks submit
- **WHEN** an upload is in progress (`progress < 100`)
- **THEN** the Submit button is disabled and shows a spinner/"Uploading..." label until upload completes or fails

#### Scenario: Guard against silent nil resume
- **WHEN** a candidate picked a file but that file has validation errors or did not complete upload, and they click Submit
- **THEN** the system does not create an application with `resume_url=nil` silently; instead it keeps the form open, keeps the error visible, and shows "Please fix the resume upload or remove the file to apply without a CV."

### Requirement: Logo upload
The system SHALL allow admins to upload a company logo.

#### Scenario: Upload logo
- **WHEN** an admin uploads a logo file
- **THEN** the file is validated (size ≤ 5MB, type: png/jpg/svg)
- **AND** uploaded to S3 under `/{tenant_id}/logos/{filename}`
- **AND** the tenant settings are updated with the logo URL

### Requirement: S3 storage
The system SHALL store files in S3-compatible storage.

#### Scenario: S3 configuration
- **WHEN** the application starts
- **THEN** it connects to S3 using configured credentials

#### Scenario: Self-hosted S3 (RustFS)
- **WHEN** the application is deployed self-hosted
- **THEN** RustFS runs as a Docker Compose service alongside PostgreSQL

### Requirement: Resume access
The system SHALL provide secure access to uploaded resumes.

#### Scenario: View resume
- **WHEN** an authenticated user views a candidate's application
- **THEN** they can access the resume via a secure URL

#### Scenario: Unauthenticated access
- **WHEN** an unauthenticated user tries to access a resume URL
- **THEN** the system returns a 403 Forbidden error
