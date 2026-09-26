## MODIFIED Requirements

### Requirement: Send team invite
The system SHALL allow memberships passing `team_manage` to invite new team members via email with preset roles `admin`, `recruiter`, or `interviewer`. Invites SHALL target the current workspace identified by the URL slug.

#### Scenario: Send invite
- **WHEN** a user with `team_manage` on `/:tenant_slug/app/settings/team` enters an email address and a preset role
- **THEN** an invite record is created with a unique token for that tenant
- **AND** an email is sent to the invitee with a registration link

#### Scenario: Invite expires
- **WHEN** an invite is older than 7 days
- **THEN** the invite link is no longer valid

#### Scenario: Denied user cannot invite
- **WHEN** a user without `team_manage` attempts to invite
- **THEN** the system returns a permission error

### Requirement: Accept team invite
The system SHALL allow invitees to join the workspace via the invite link. If the invite email already belongs to an existing identity, the system SHALL re-use that identity by creating a membership rather than a duplicate user.

#### Scenario: Valid invite link for new identity
- **WHEN** an invitee visits /invite/:token with a valid token and the invite email does not exist in the system
- **THEN** they see a registration form with their email pre-filled

#### Scenario: Complete registration for new identity
- **WHEN** an invitee with a new email submits name and password via the invite form
- **THEN** a new user is created with a bcrypt-hashed password
- **AND** a membership linking the user to the tenant with the invited preset role is created
- **AND** the invite is marked as accepted
- **AND** the user is redirected to `/:tenant_slug/app`

#### Scenario: Invite for existing identity (re-fetch)
- **WHEN** an invitee visits /invite/:token and the invite email already belongs to an existing user
- **THEN** the system re-fetches the user by invite.email as the authoritative identity
- **AND** if the visitor is not authenticated it prompts them to log in as that email
- **AND** if the visitor is authenticated as the same user it creates a membership for the tenant (idempotently) and redirects to `/:tenant_slug/app`
- **AND** if the visitor is authenticated as a different user it shows an interstitial: "You're logged in as X but this invite is for Y — Log out and continue as Y"

#### Scenario: Idempotent membership on re-accept
- **WHEN** an invite for an email that already has a membership for that tenant is visited
- **THEN** the system does not create a duplicate membership and redirects to `/:tenant_slug/app`

#### Scenario: Invalid invite
- **WHEN** an invitee visits /invite/:token with an invalid or expired token
- **THEN** the system redirects to the login page and displays the error "Invalid or expired invite link" there, so the invitee actually sees why they landed on login

### Requirement: Role-based access control
The system SHALL enforce action-based access for `admin`, `recruiter`, and `interviewer` preset roles. The role SHALL be taken from the current membership for the active workspace, not from the user row, and resolved to effective permissions with workspace overrides.

#### Scenario: Admin permissions
- **WHEN** the current membership has role "admin" for the active workspace
- **THEN** the user passes every action check in that workspace

#### Scenario: Recruiter permissions
- **WHEN** the current membership has role "recruiter" for the active workspace
- **THEN** they can perform hiring operations per preset defaults plus workspace overrides
- **AND** they cannot perform denied administrative actions in that workspace

#### Scenario: Interviewer permissions
- **WHEN** the current membership has role "interviewer" for the active workspace
- **THEN** they can view scoped jobs/candidates, list interviews, submit scorecards, and manage own availability
- **AND** they cannot perform hiring mutations or administration outside their grant

#### Scenario: Mixed roles across workspaces
- **WHEN** a user is admin in tenant A and recruiter in tenant B
- **THEN** navigating to `/:slug_A/app` grants full access and navigating to `/:slug_B/app` grants the recruiter effective set

### Requirement: List team members
The system SHALL display all memberships in the current workspace identified by the URL slug.

#### Scenario: Team page
- **WHEN** a user with `team_manage` navigates to `/:tenant_slug/app/settings/team`
- **THEN** all members with a membership for that tenant are listed with name, email, and preset role

#### Scenario: Remove team member
- **WHEN** a user with `team_manage` removes a team member from the current workspace
- **THEN** the membership linking that user to the tenant is removed
- **AND** the user row remains and the user keeps memberships in other tenants
- **AND** their notes remain visible (attributed to "Former member")
