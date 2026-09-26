## ADDED Requirements

### Requirement: Admin permission matrix per workspace
The system SHALL provide a Roles & permissions matrix in Settings → Team visible only to memberships passing `team_manage`. The matrix SHALL list grouped actions as rows and non-admin roles (`recruiter`, `interviewer`) as columns with toggle controls. The `admin` column SHALL be shown as locked (all allowed, not toggleable).

#### Scenario: Admin opens matrix
- **WHEN** an admin with `team_manage` opens Settings → Team → Roles & permissions
- **THEN** grouped actions appear with plain-language labels and current allowed state per role

#### Scenario: Non-admin cannot open matrix
- **WHEN** a recruiter or interviewer navigates to the matrix
- **THEN** the system redirects with a permission-denied flash

#### Scenario: Toggle persists per workspace
- **WHEN** an admin toggles an editable action for a role and saves
- **THEN** the override is stored scoped to that workspace only and other workspaces are unaffected

### Requirement: Permission changes are audited and applied promptly
Every matrix save SHALL write one audit event recording actor, workspace, role, action, and old/new values. After save, subsequent mounts, permission checks, and agent context builds SHALL use the new values; in-flight confirmed runs SHALL re-check with current values.

#### Scenario: Audit trail
- **WHEN** an admin changes `candidates_delete` for `recruiter` from denied to allowed
- **THEN** an audit event exists with actor, workspace, role, action, and before/after values

#### Scenario: New value applies on next navigation
- **WHEN** an admin allows an action and the affected user navigates to the previously denied page
- **THEN** the page loads instead of redirecting

### Requirement: Invites and role changes use preset roles
Invite creation and member role updates SHALL offer exactly `admin`, `recruiter`, and `interviewer`. Invite acceptance SHALL create the membership with the invited preset role.

#### Scenario: Invite with new presets
- **WHEN** an admin invites `colleague@company.com` as `interviewer`
- **THEN** the invite stores that role and acceptance creates an `interviewer` membership

#### Scenario: Role update re-resolves permissions
- **WHEN** an admin changes a member from `recruiter` to `interviewer`
- **THEN** subsequent checks use the interviewer effective set
