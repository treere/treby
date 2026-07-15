# File Upload

## Purpose

Handle secure file uploads for resumes and logos with S3/MinIO-compatible storage.

## Requirements

### Requirement: Resume upload
The system SHALL allow uploading resumes as part of the application process.

#### Scenario: Upload resume file
- **WHEN** a candidate selects a file for resume upload
- **THEN** the file is validated (size ≤ 10MB, type: pdf/doc/docx)
- **AND** uploaded to S3 under `/{tenant_id}/resumes/{candidate_id}/{filename}`

#### Scenario: Resume too large
- **WHEN** a candidate uploads a file larger than 10MB
- **THEN** the system returns an error: "File too large"

### Requirement: Logo upload
The system SHALL allow admins to upload a company logo.

#### Scenario: Upload logo
- **WHEN** an admin uploads a logo file
- **THEN** the file is validated (size ≤ 5MB, type: png/jpg/svg)
- **AND** uploaded to S3 under `/{tenant_id}/logos/{filename}`
- **AND** the tenant settings are updated with the logo URL

### Requirement: S3/MinIO storage
The system SHALL store files in S3-compatible storage.

#### Scenario: MinIO configuration
- **WHEN** the application starts
- **THEN** it connects to S3/MinIO using configured credentials

#### Scenario: Self-hosted MinIO
- **WHEN** the application is deployed self-hosted
- **THEN** MinIO runs as a Docker Compose service alongside PostgreSQL

### Requirement: Resume access
The system SHALL provide secure access to uploaded resumes.

#### Scenario: View resume
- **WHEN** an authenticated user views a candidate's application
- **THEN** they can access the resume via a secure URL

#### Scenario: Unauthenticated access
- **WHEN** an unauthenticated user tries to access a resume URL
- **THEN** the system returns a 403 Forbidden error
