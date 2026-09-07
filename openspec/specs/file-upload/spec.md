# File Upload

## Purpose

Handle secure file uploads for resumes and logos with S3-compatible storage (RustFS in dev).

## Requirements

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
The system SHALL store files in S3-compatible storage. The bucket name SHALL be configurable via runtime config `config :treby, :s3_bucket` and environment variable `S3_BUCKET` (fallback `TREBY_S3_BUCKET`), defaulting to `"treby-uploads"` when unset. The system SHALL enforce tenant-scoped keys: `upload_file`, `get_presigned_url`, and `delete_file` take the tenant id and raise `ArgumentError` for keys not prefixed with `"#{tenant_id}/"`, so cross-tenant access is impossible even on programmer error.

#### Scenario: S3 configuration
- **WHEN** the application starts
- **THEN** it connects to S3 using configured credentials

#### Scenario: Bucket configurable via env
- **WHEN** `S3_BUCKET` is set to a custom value (e.g., `my-bucket`)
- **THEN** `Treby.Uploads` operations (`upload_file`, `get_presigned_url`, `delete_file`, `ensure_bucket_exists!`) use that bucket instead of the hardcoded `"treby-uploads"`

#### Scenario: Default bucket when env unset
- **WHEN** neither `S3_BUCKET` nor `TREBY_S3_BUCKET` is set
- **THEN** `Treby.Uploads` uses the default bucket `"treby-uploads"`

#### Scenario: Self-hosted S3 (RustFS)
- **WHEN** the application is deployed self-hosted
- **THEN** RustFS runs as a Docker Compose service alongside PostgreSQL

#### Scenario: Tenant-scoped key helper
- **WHEN** a caller constructs a key via `Treby.Uploads.scoped_key(tenant_id, key)`
- **THEN** the helper returns the key unchanged if it starts with `"#{tenant_id}/"` and raises otherwise, preventing cross-tenant access

#### Scenario: Non-tenant key rejected at the boundary
- **WHEN** `upload_file` or `get_presigned_url` is called with a key not prefixed with the caller's tenant id
- **THEN** the operation raises `ArgumentError` and no S3 request is made

### Requirement: Resume access
The system SHALL provide secure access to uploaded resumes.

#### Scenario: View resume
- **WHEN** an authenticated user views a candidate's application
- **THEN** they can access the resume via a secure URL

#### Scenario: Unauthenticated access
- **WHEN** an unauthenticated user tries to access a resume URL
- **THEN** the system returns a 403 Forbidden error
