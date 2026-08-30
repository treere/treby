## ADDED Requirements

### Requirement: Workspace picker on login
The system SHALL display a workspace picker when an authenticated user belongs to multiple tenants.

#### Scenario: Multiple memberships after login
- **WHEN** a user successfully logs in and has two or more memberships
- **THEN** the system redirects to `/choose-tenant` which lists all workspaces with their slug, name, and the user's role in each
- **AND** the user can select a workspace to continue

#### Scenario: Single membership auto-redirect
- **WHEN** a user logs in and has exactly one membership
- **THEN** the system redirects directly to `/:tenant_slug/app` without showing the picker

#### Scenario: Picker enforces membership
- **WHEN** a user on `/choose-tenant` selects a workspace
- **THEN** the system verifies the user has a membership for that tenant before redirecting
- **AND** rejects the selection with an error if no membership exists

### Requirement: In-app workspace switcher
The system SHALL provide an in-app switcher to change the active workspace without logging out.

#### Scenario: Switcher visibility
- **WHEN** an authenticated user has more than one membership
- **THEN** the app header (and mobile drawer) shows a switcher listing all workspaces with the active one marked
- **WHEN** the user has only one membership
- **THEN** the switcher is hidden

#### Scenario: Switching workspace
- **WHEN** a user selects a different workspace from the switcher
- **THEN** the system navigates to `/:new_tenant_slug/app` for that workspace
- **AND** subsequent requests are scoped to the new tenant

#### Scenario: Create new company from switcher
- **WHEN** a user clicks "Create new company" in the switcher
- **THEN** a form to enter the new company name is shown
- **AND** on submit a new tenant with a unique slug is created
- **AND** a membership with role "admin" for the current user is created
- **AND** the user is redirected to `/:new_tenant_slug/app`

### Requirement: Workspace context propagation
The system SHALL propagate the active workspace context to all authenticated pages and assign it for use in templates and authorization.

#### Scenario: Current workspace assigned
- **WHEN** a user is on `/:tenant_slug/app/*`
- **THEN** the system assigns `current_user`, `current_tenant` (from slug), `current_membership` (for that pair), and `available_tenants`

#### Scenario: Deep link preserves workspace
- **WHEN** a user shares a link `/:tenant_slug/app/jobs/:id`
- **THEN** a recipient with membership for that tenant sees the same job in that workspace
- **AND** a recipient without membership sees 403 or is redirected to `/choose-tenant`
