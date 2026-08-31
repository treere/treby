## MODIFIED Requirements

### Requirement: Candidate OTP session tenant binding
The system SHALL bind the candidate OTP session to the candidate's tenant and validate the URL slug on every portal request.

#### Scenario: Slug matches candidate tenant
- **WHEN** a candidate accesses `/:tenant_slug/portal` where `tenant_slug` matches their own tenant
- **THEN** the request succeeds and the tenant branding for their tenant is shown

#### Scenario: Slug does not match candidate tenant
- **WHEN** a candidate accesses `/:other_slug/portal` where the slug differs from their tenant
- **THEN** the system redirects to `/:own_tenant_slug/portal` (or to login with a flash) and does not render the mismatched tenant's data
