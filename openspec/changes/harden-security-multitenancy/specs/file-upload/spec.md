## MODIFIED Requirements

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
