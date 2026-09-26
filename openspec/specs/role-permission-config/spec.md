# Role Permission Configuration

## Purpose

Let workspace admins delegate safely by toggling which actions each non-admin preset role may perform, with every change audited and applied to both the UI and the AI agent.

## Requirements

### Requirement: Admin permission matrix per workspace
The system SHALL provide a Roles & permissions matrix in Settings → Team visible only to memberships passing `team_manage`. The matrix SHALL list grouped actions as rows and `recruiter`/`interviewer` as toggleable columns. The `admin` column SHALL be shown as locked.

#### Scenario: Admin opens matrix
- **WHEN** an admin with `team_manage` opens Settings → Team → Roles & permissions
- **THEN** grouped actions appear with current allowed state per role

#### Scenario: Non-admin cannot use matrix
- **WHEN** a recruiter or interviewer attempts to toggle a permission
- **THEN** the system returns a permission error

#### Scenario: Toggle persists per workspace
- **WHEN** an admin toggles an editable action for a role and saves
- **THEN** the override is stored scoped to that workspace only

### Requirement: Permission changes are audited and applied promptly
Every matrix save SHALL write one audit event recording actor, workspace, role, action, and new value. Subsequent mounts, permission checks, and agent context builds SHALL use the new values; confirmed agent runs SHALL re-check current values.

#### Scenario: Audit trail
- **WHEN** an admin changes an action grant for a role
- **THEN** an audit event exists with actor, workspace, role, action, and new value

#### Scenario: New value applies on next navigation
- **WHEN** an admin allows an action and the affected user navigates to the previously denied page
- **THEN** the page loads instead of redirecting

### Requirement: Invites and role changes use preset roles
Invite creation and member role updates SHALL offer exactly `admin`, `recruiter`, and `interviewer`. Invite acceptance SHALL create the membership with the invited preset role.

#### Scenario: Invite with new presets
- **WHEN** an admin invites someone as `interviewer`
- **THEN** acceptance creates an `interviewer` membership

#### Scenario: Role update re-resolves permissions
- **WHEN** an admin changes a member from `recruiter` to `interviewer`
- **THEN** subsequent checks use the interviewer effective set
