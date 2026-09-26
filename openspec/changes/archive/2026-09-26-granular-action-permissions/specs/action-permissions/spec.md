## ADDED Requirements

### Requirement: Action keys are the single permission unit
The system SHALL define a stable set of grouped action keys (about 15-20) covering hiring operations, configuration, team, privacy, and integrations. Both UI guards and AI tools SHALL check these keys instead of raw role strings.

#### Scenario: Unknown action denies
- **WHEN** a check references an action key that does not exist
- **THEN** the system denies access

#### Scenario: Same key gates UI and agent
- **WHEN** a tool and a UI route declare the same action key
- **THEN** allowing the key allows both and denying it denies both

### Requirement: Preset roles with locked admin
The system SHALL provide preset workspace roles `admin`, `recruiter`, and `interviewer`. The `admin` role SHALL grant all actions and SHALL NOT be editable. Preset defaults SHALL apply when no per-workspace override exists.

#### Scenario: Admin has all actions
- **WHEN** the current membership has role `admin`
- **THEN** every action check passes

#### Scenario: Recruiter gets operational defaults
- **WHEN** the current membership has role `recruiter` with no overrides
- **THEN** hiring operations (view/create/update jobs, candidates, applications, notes, interviews scheduling, messaging, `:privacy_view` for listing/creating data-privacy requests) pass
- **AND** workspace administration (team management, settings, webhooks, audit, deletes, merge, bulk delete, imports, `:privacy_manage` for tenant export/erasure) is denied unless an admin explicitly allows it

#### Scenario: Privacy view versus privacy manage
- **WHEN** a recruiter lists or creates a data-privacy request
- **THEN** the `:privacy_view` check passes by default
- **WHEN** the same recruiter requests tenant export/erasure
- **THEN** the `:privacy_manage` check fails unless an admin explicitly allowed it

#### Scenario: Interviewer gets scoped defaults
- **WHEN** the current membership has role `interviewer` with no overrides
- **THEN** view jobs/candidates/pipelines, list interviews, submit scorecards, and manage own availability pass
- **AND** all destructive and administrative actions are denied unless an admin explicitly allows them

### Requirement: Effective permission resolution per workspace
The system SHALL resolve effective permissions as preset default plus per-workspace role overrides, always scoped by `tenant_id`. The role SHALL come from the current membership for the active workspace, never from the user row.

#### Scenario: Override wins over default
- **WHEN** an admin allows `pipeline_manage` for `recruiter` in tenant A
- **THEN** recruiters in tenant A pass that check and recruiters in tenant B still fail it

#### Scenario: Mixed roles across workspaces
- **WHEN** a user is `admin` in tenant A and `recruiter` in tenant B
- **THEN** tenant A grants all actions and tenant B grants only the recruiter set

#### Scenario: Nil or unknown role denies
- **WHEN** the membership is missing or the role value is unrecognized
- **THEN** all action checks fail closed

### Requirement: Legacy member migration
Existing memberships and invites with role `member` SHALL migrate to `recruiter` with identical effective behavior (recruiter defaults equal old member capabilities). No workspace SHALL gain or lose access on migration except through later admin toggles.

#### Scenario: Member becomes recruiter
- **WHEN** the migration runs on a workspace with `member` memberships
- **THEN** those memberships have role `recruiter` and keep the same allowed actions as before

#### Scenario: Pending member invites become recruiter invites
- **WHEN** the migration runs with pending `member` invites
- **THEN** those invites carry role `recruiter`
