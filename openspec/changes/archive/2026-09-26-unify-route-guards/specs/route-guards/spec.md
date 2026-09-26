## ADDED Requirements

### Requirement: Membership gate resolves access from slug

The system SHALL resolve tenant, membership, and available workspaces from `(user_id, tenant_slug)` through a single core used by both controller and LiveView guards.

#### Scenario: Valid membership

- **WHEN** a logged-in user with a membership visits a workspace route
- **THEN** the request continues with tenant, membership, and workspace list assigned

#### Scenario: Unknown workspace slug on controller route

- **WHEN** the slug matches no workspace
- **THEN** the system responds 404

#### Scenario: Unknown workspace slug on LiveView route

- **WHEN** the slug matches no workspace
- **THEN** the system halts and redirects to workspace choice with an error flash

#### Scenario: No membership in workspace

- **WHEN** a logged-in user without membership visits a workspace route
- **THEN** the system redirects to workspace choice with an error flash

### Requirement: Permission gate checks action against assigned membership

The system SHALL grant page access when the resolved actor has any of the required actions, and halt with redirect plus error flash otherwise.

#### Scenario: Actor has the action

- **WHEN** the actor's permission set includes the required action
- **THEN** navigation continues

#### Scenario: Actor lacks the action

- **WHEN** the actor's permission set excludes all required actions
- **THEN** the system halts and redirects to the workspace dashboard (or workspace choice when no slug) with an error flash

#### Scenario: Multiple required actions use any-of semantics

- **WHEN** several actions are required and the actor has at least one
- **THEN** navigation continues

### Requirement: Guards fail closed without session

The system SHALL never raise or continue on missing credentials.

#### Scenario: Anonymous visitor on guarded route

- **WHEN** no user session exists
- **THEN** the system redirects to login (LiveView) or denies with 404/login per transport

#### Scenario: Permission hook mounted without membership assigns

- **WHEN** no membership is assigned and none resolves
- **THEN** the system denies access via the no-membership redirect path
