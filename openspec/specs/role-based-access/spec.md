# Role-Based Access Control

## Purpose

Enforce action-based permissions across all LiveViews and context functions so workspaces can delegate operational work without granting full admin, while the UI hides every denied action.

## Requirements

### Requirement: Permission-gated settings access
The system SHALL restrict each settings page by its declared action (e.g. pipeline pages require `pipeline_manage`, webhooks require `webhooks_manage`, audit log requires `audit_view`, team requires `team_manage`). Direct navigation without the action SHALL redirect to the dashboard with a permission-denied flash, and the sidebar SHALL hide denied items and empty groups.

#### Scenario: Permitted user accesses settings
- **WHEN** a recruiter with explicitly allowed `pipeline_manage` navigates to the pipeline settings page
- **THEN** the page loads normally

#### Scenario: Denied user accesses settings
- **WHEN** a user without the page's required action navigates to that settings page
- **THEN** the system redirects to the dashboard with a permission-denied flash message

### Requirement: Team management requires team_manage
The system SHALL restrict team invitations, role changes, and removals to memberships passing `team_manage` (admin by default).

#### Scenario: Permitted user invites team member
- **WHEN** a user with `team_manage` sends a team invitation
- **THEN** the invitation is created and emailed

#### Scenario: Denied user attempts to invite
- **WHEN** a user without `team_manage` attempts to invite a team member
- **THEN** the system returns a permission error

#### Scenario: Permitted user removes team member
- **WHEN** a user with `team_manage` removes a team member
- **THEN** the member is removed from the tenant

### Requirement: Pipeline configuration requires pipeline permissions
The system SHALL restrict pipeline stage management to `pipeline_manage` and stage-people assignment to `pipeline_assign`.

#### Scenario: Permitted user manages pipeline stages
- **WHEN** a user with `pipeline_manage` creates, edits, reorders, or deletes pipeline stages
- **THEN** the changes are applied

#### Scenario: Denied user attempts pipeline configuration
- **WHEN** a user without `pipeline_manage` attempts to manage pipeline stages
- **THEN** the system returns a permission error

#### Scenario: Permitted user manages stage roles
- **WHEN** a user with `pipeline_assign` assigns examiners, reviewers, or advancers
- **THEN** the assignments are saved

### Requirement: Destructive candidate actions require explicit grants
The system SHALL restrict candidate deletion to `candidates_delete` and merging to `candidates_merge` (both admin-only by default, grantable per workspace).

#### Scenario: Permitted user deletes candidate
- **WHEN** a user with `candidates_delete` deletes a candidate
- **THEN** the candidate is removed

#### Scenario: Denied user attempts deletion
- **WHEN** a user without `candidates_delete` attempts to delete a candidate
- **THEN** the system returns a permission error

### Requirement: Template management split by action
The system SHALL restrict email template management to `settings_manage`, scorecard template management to `scorecards_manage`, and allow scorecard submission with only `scorecards_submit`. Custom field management SHALL require `fields_manage`.

#### Scenario: Interviewer submits scorecard
- **WHEN** an interviewer with `scorecards_submit` submits a scorecard for an assigned interview
- **THEN** the submission is saved

#### Scenario: Denied user attempts template management
- **WHEN** a user without the matching manage action attempts to manage templates or custom fields
- **THEN** the system returns a permission error

### Requirement: Preset operational permissions
`recruiter` defaults SHALL cover notes, stage moves (subject to advancer rules), interview scheduling, job and candidate create/update, messaging, availability, and analytics. `interviewer` defaults SHALL cover scoped viewing, interview listing, scorecard submission, and own availability.

#### Scenario: Recruiter works daily hiring flow
- **WHEN** a recruiter adds a note, moves a candidate (as advancer), or schedules an interview
- **THEN** each action succeeds

#### Scenario: Interviewer cannot mutate hiring flow
- **WHEN** an interviewer without `applications_move` attempts to move a candidate
- **THEN** the system returns a permission error even if they examine for the stage

### Requirement: Advancer plus action for stage advancement
Candidate advancement from a stage SHALL require the user to be an assigned advancer (or hold `pipeline_manage`) AND to pass `applications_move`. Both conditions must hold.

#### Scenario: Advancer advances candidate
- **WHEN** a stage advancer with `applications_move` advances a candidate with complete requirements
- **THEN** the advancement proceeds

#### Scenario: Advancer without action permission attempts advancement
- **WHEN** a stage advancer lacks `applications_move`
- **THEN** the system prevents the action with a permission error

#### Scenario: Non-advancer attempts advancement
- **WHEN** a user who is neither an advancer for the stage nor a pipeline manager attempts to advance
- **THEN** the system prevents the action with a permission error

### Requirement: Audit log requires audit_view
The system SHALL restrict the audit log view and audit query API to memberships passing `audit_view` (admin-only, not grantable in v1).

#### Scenario: Permitted user accesses audit log
- **WHEN** a user with `audit_view` opens the audit log or queries audit events
- **THEN** the request succeeds with tenant-scoped events

#### Scenario: Denied user denied audit log access
- **WHEN** a user without `audit_view` opens the audit log
- **THEN** the system denies access with a permission-denied flash or error

### Requirement: LiveView checks resolve through unified policy
All LiveView and hook permission checks SHALL resolve through the unified policy check with an actor built by the single actor builder, preserving existing grant/deny decisions and fail-closed behavior.

#### Scenario: Settings guard unchanged
- **WHEN** a user without the page action navigates to a settings page
- **THEN** the system still redirects to the dashboard with a permission-denied flash

#### Scenario: Template guard unchanged
- **WHEN** a template renders a gated action
- **THEN** visibility matches the previous helper result for the same membership
