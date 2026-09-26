# Action Permissions

## Purpose

Define workspace authorization as stable action keys resolved to effective permission sets per membership, replacing the binary admin/member gate with one contract shared by the UI and the AI agent.

## Requirements

### Requirement: Stable action keys
The system SHALL define a stable set of grouped action keys covering hiring operations, scheduling, workspace configuration, and integrations. UI guards and AI tools SHALL check these keys instead of raw role strings.

#### Scenario: Unknown action denies
- **WHEN** a check references an action key that does not exist
- **THEN** the system denies access

#### Scenario: Same key gates UI and agent
- **WHEN** a tool and a UI route declare the same action key
- **THEN** allowing the key allows both and denying it denies both

### Requirement: Preset roles with locked admin
The system SHALL provide preset workspace roles `admin`, `recruiter`, and `interviewer`. The `admin` role SHALL grant all actions and SHALL NOT be editable. Preset defaults SHALL apply when no per-workspace override exists. The retired `member` role SHALL normalize to `recruiter`.

#### Scenario: Admin has all actions
- **WHEN** the current membership has role `admin`
- **THEN** every action check passes

#### Scenario: Recruiter gets operational defaults
- **WHEN** the current membership has role `recruiter` with no overrides
- **THEN** hiring operations (jobs, candidates, applications, notes, interviews, messaging, analytics, `:privacy_view` for listing/creating data-privacy requests) pass
- **AND** team management, settings, webhooks, audit, deletes, merge, imports, and `:privacy_manage` for tenant export/erasure are denied unless explicitly allowed

#### Scenario: Privacy view versus privacy manage
- **WHEN** a recruiter lists or creates a data-privacy request
- **THEN** the `:privacy_view` check passes by default
- **WHEN** the same recruiter requests tenant export/erasure
- **THEN** the `:privacy_manage` check fails unless an admin explicitly allowed it

#### Scenario: Interviewer gets scoped defaults
- **WHEN** the current membership has role `interviewer` with no overrides
- **THEN** viewing jobs/candidates/pipelines/interviews, submitting scorecards, and managing own availability pass
- **AND** all mutations and administration are denied unless explicitly allowed

### Requirement: Effective resolution is workspace-scoped and fail-closed
The system SHALL resolve effective permissions as preset default plus per-workspace overrides, always scoped by `tenant_id`, from the current membership role. Nil, missing, or unrecognized roles SHALL deny every action.

#### Scenario: Override wins over default within one workspace
- **WHEN** an admin allows an action for `recruiter` in tenant A
- **THEN** recruiters in tenant A pass and recruiters in tenant B still fail

#### Scenario: Mixed roles across workspaces
- **WHEN** a user is `admin` in tenant A and `recruiter` in tenant B
- **THEN** tenant A grants all actions and tenant B grants the recruiter set
