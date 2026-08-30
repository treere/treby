## MODIFIED Requirements

### Requirement: Tenant data isolation
The system SHALL isolate data between tenants using tenant_id on all domain tables. Access to a tenant's data SHALL require an active membership for that tenant.

#### Scenario: Tenant created with default settings
- **WHEN** a new tenant is created
- **THEN** it has a unique slug, name, and empty settings JSONB

#### Scenario: Query scoping
- **WHEN** a user queries any resource (jobs, candidates, applications)
- **THEN** only resources belonging to the current tenant from the URL are returned

#### Scenario: Membership-gated access
- **WHEN** a user without a membership for tenant X requests `/:tenant_slug/app/*` where slug resolves to X
- **THEN** the system denies access with 403 or redirects to `/choose-tenant`

### Requirement: Tenant slug identification
The system SHALL identify tenants by slug in public URLs and in authenticated workspace URLs. Slugs SHALL be immutable after creation.

#### Scenario: Career page URL
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** the system loads the tenant matching that slug

#### Scenario: Workspace URL
- **WHEN** an authenticated user navigates to `/:tenant_slug/app` or `/:tenant_slug/app/*`
- **THEN** the system loads the tenant matching that slug and verifies membership before rendering

#### Scenario: Invalid slug
- **WHEN** a visitor navigates to `/:invalid_slug/careers` or `/:invalid_slug/app`
- **THEN** the system returns a 404 page

### Requirement: Default pipeline stages
The system SHALL create default pipeline stages when a tenant is created.

#### Scenario: New tenant gets default stages
- **WHEN** a new tenant is created
- **THEN** it has pipeline stages: New, Screen, Phone Screen, Interview, Offer, Hired (in that order)

### Requirement: Self-hosted single tenant mode
The system SHALL support single-tenant deployments for self-hosted usage.

#### Scenario: Self-hosted installation
- **WHEN** the application is deployed as self-hosted
- **THEN** a default tenant is created on first run
- **AND** all routes work with that tenant's slug
- **AND** the workspace picker and switcher are hidden when the user has only one membership

## ADDED Requirements

### Requirement: Membership model
The system SHALL maintain a membership per (user, tenant) pair that stores the user's role and timestamps within that tenant.

#### Scenario: Membership created on registration
- **WHEN** a new user registers and a tenant is created
- **THEN** a membership is created linking the user to that tenant with role "admin"

#### Scenario: Membership created on invite acceptance
- **WHEN** an invite for tenant B is accepted by an existing user who already belongs to tenant A
- **THEN** a new membership linking that user to tenant B with the invited role is created
- **AND** no duplicate user row is created

#### Scenario: Role is per membership
- **WHEN** a user belongs to tenant A as admin and tenant B as member
- **THEN** the system enforces admin permissions in A and member permissions in B based on the membership's role for the current workspace

#### Scenario: Membership uniqueness
- **WHEN** a membership already exists for a given user and tenant
- **THEN** creating a duplicate membership is rejected

### Requirement: URL-scoped workspace routing
The system SHALL route all authenticated application pages under `/:tenant_slug/app/*` where the slug identifies the active workspace.

#### Scenario: Authenticated navigation preserves workspace
- **WHEN** a user navigates between pages inside the app
- **THEN** all links include the current tenant slug
- **AND** the active workspace remains the one in the URL

#### Scenario: Legacy /app redirect
- **WHEN** a user visits the legacy path `/app` or `/app/*`
- **THEN** the system redirects to `/choose-tenant` or to the user's sole workspace at `/:tenant_slug/app`
