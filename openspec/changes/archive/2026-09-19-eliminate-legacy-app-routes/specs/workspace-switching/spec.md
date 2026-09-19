## MODIFIED Requirements

### Requirement: Workspace context propagation
The system SHALL propagate the active workspace context to all authenticated pages and assign it for use in templates and authorization.

#### Scenario: Current workspace assigned
- **WHEN** a user is on `/:tenant_slug/app/*`
- **THEN** the system assigns `current_user`, `current_tenant` (from slug), `current_membership` (for that pair), and `available_tenants`

#### Scenario: Deep link preserves workspace
- **WHEN** a user shares a link `/:tenant_slug/app/jobs/:id`
- **THEN** a recipient with membership for that tenant sees the same job in that workspace
- **AND** a recipient without membership sees 403 or is redirected to `/choose-tenant`
- **AND** a link without slug such as `/app/jobs/:id` redirects to the tenant-scoped equivalent before access checks
