## ADDED Requirements

### Requirement: Send team invite
The system SHALL allow admins to invite new team members via email.

#### Scenario: Send invite
- **WHEN** an admin enters an email address and role
- **THEN** an invite record is created with a unique token
- **AND** an email is sent to the invitee with a registration link

#### Scenario: Invite expires
- **WHEN** an invite is older than 7 days
- **THEN** the invite link is no longer valid

### Requirement: Accept team invite
The system SHALL allow invitees to register via the invite link.

#### Scenario: Valid invite link
- **WHEN** an invitee visits /invites/:token with a valid token
- **THEN** they see a registration form with their email pre-filled

#### Scenario: Complete registration
- **WHEN** an invitee submits name and password via the invite form
- **THEN** a new user is created with the invited role
- **AND** the user is linked to the tenant
- **AND** the invite is marked as accepted

#### Scenario: Invalid invite
- **WHEN** an invitee visits /invites/:token with an invalid or expired token
- **THEN** the system shows an error: "Invalid or expired invite"

### Requirement: Role-based access control
The system SHALL enforce role-based access for admin and member roles.

#### Scenario: Admin permissions
- **WHEN** a user has the "admin" role
- **THEN** they can manage settings, team members, pipeline stages, and custom fields

#### Scenario: Member permissions
- **WHEN** a user has the "member" role
- **THEN** they can view and edit jobs, candidates, applications, and notes
- **AND** they cannot access settings or team management

### Requirement: List team members
The system SHALL display all users in the current tenant.

#### Scenario: Team page
- **WHEN** an admin navigates to Settings → Team
- **THEN** all team members are listed with name, email, and role

#### Scenario: Remove team member
- **WHEN** an admin removes a team member
- **THEN** the user is disassociated from the tenant
- **AND** their notes remain visible (attributed to "Former member")
