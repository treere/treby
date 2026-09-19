## MODIFIED Requirements

### Requirement: URL-scoped workspace routing
The system SHALL route all authenticated application pages under `/:tenant_slug/app/*` where the slug identifies the active workspace. The legacy prefix `/app/*` SHALL NOT render LiveViews; it SHALL redirect to the tenant-scoped equivalent or to `/choose-tenant`.

#### Scenario: Authenticated navigation preserves workspace
- **WHEN** a user navigates between pages inside the app
- **THEN** all links include the current tenant slug
- **AND** the active workspace remains the one in the URL

#### Scenario: Legacy /app redirect
- **WHEN** a user visits the legacy path `/app` or `/app/*`
- **THEN** the system redirects to `/:tenant_slug/app` (sole membership) or to `/choose-tenant` (multiple memberships) or to `/login` (no session), preserving the original path and query
- **AND** no LiveView is rendered at the legacy path
