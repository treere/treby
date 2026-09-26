## MODIFIED Requirements

### Requirement: Admin-only settings access
The system SHALL restrict settings pages by action permission instead of raw admin role. Each settings page SHALL declare its required action (e.g. pipeline pages require `pipeline_manage`, webhooks require `webhooks_manage`, audit log requires `audit_view`, team requires `team_manage`).

#### Scenario: Permitted member accesses settings
- **WHEN** a recruiter with explicitly allowed `pipeline_manage` navigates to the pipeline settings page
- **THEN** the page loads normally

#### Scenario: Denied user accesses settings
- **WHEN** a user without the page's required action navigates to that settings page
- **THEN** the system redirects to the dashboard with a "permission denied" flash message

### Requirement: Admin-only team management
The system SHALL restrict team invitations, role changes, and removals to memberships passing `team_manage` (admin by default).

#### Scenario: Admin invites team member
- **WHEN** an admin sends a team invitation
- **THEN** the invitation is created and emailed

#### Scenario: Member attempts to invite
- **WHEN** a recruiter without `team_manage` attempts to invite a team member
- **THEN** the system returns a permission error

#### Scenario: Admin removes team member
- **WHEN** an admin removes a team member
- **THEN** the member is removed from the tenant

#### Scenario: Member attempts to remove
- **WHEN** a recruiter without `team_manage` attempts to remove a team member
- **THEN** the system returns a permission error

### Requirement: Admin-only pipeline configuration
The system SHALL restrict pipeline stage management and stage-people assignment to memberships passing `pipeline_manage` and `pipeline_assign_people` respectively.

#### Scenario: Permitted recruiter manages pipeline stages
- **WHEN** a recruiter with allowed `pipeline_manage` creates, edits, reorders, or deletes pipeline stages
- **THEN** the changes are applied

#### Scenario: Denied user attempts pipeline configuration
- **WHEN** a user without `pipeline_manage` attempts to create, edit, or delete pipeline stages
- **THEN** the system returns a permission error

#### Scenario: Admin manages stage roles
- **WHEN** a user with `pipeline_assign_people` assigns examiners, reviewers, or advancers to pipeline stages
- **THEN** the assignments are saved

#### Scenario: Denied user attempts stage role assignment
- **WHEN** a user without `pipeline_assign_people` attempts to assign examiners, reviewers, or advancers to pipeline stages
- **THEN** the system returns a permission error

#### Scenario: Admin configures min_examiners
- **WHEN** a user with `pipeline_manage` sets the minimum examiner count on an interview-type stage
- **THEN** the value is saved

### Requirement: Admin-only custom field management
The system SHALL restrict custom field management to memberships passing `fields_manage`.

#### Scenario: Permitted user manages custom fields
- **WHEN** a user with `fields_manage` creates, edits, or deletes custom fields
- **THEN** the changes are applied

#### Scenario: Denied user attempts custom field management
- **WHEN** a user without `fields_manage` attempts to create, edit, or delete custom fields
- **THEN** the system returns a permission error

### Requirement: Admin-only candidate deletion
The system SHALL restrict candidate deletion, merging, and bulk deletion to memberships passing `candidates_delete` and `candidates_merge` respectively (admin-only by default).

#### Scenario: Permitted user deletes candidate
- **WHEN** a user with `candidates_delete` deletes a candidate
- **THEN** the candidate is removed

#### Scenario: Denied user attempts deletion
- **WHEN** a user without `candidates_delete` attempts to delete a candidate
- **THEN** the system returns a permission error

### Requirement: Admin-only email template and scorecard management
The system SHALL restrict email template management to `settings_manage` and scorecard template management to `scorecards_manage_templates`. Submitting a filled scorecard SHALL require only `scorecards_submit`.

#### Scenario: Permitted user manages templates
- **WHEN** a user with the matching manage action creates, edits, or deletes email templates or scorecard templates
- **THEN** the changes are applied

#### Scenario: Denied user attempts template management
- **WHEN** a user without the matching manage action attempts to manage email templates or scorecard templates
- **THEN** the system returns a permission error

#### Scenario: Interviewer submits scorecard
- **WHEN** an interviewer with `scorecards_submit` submits a scorecard for an assigned interview
- **THEN** the submission is saved

### Requirement: Member permissions
The system SHALL grant day-to-day hiring actions via preset defaults plus workspace overrides. `recruiter` defaults cover notes, stage moves (subject to advancer rules), interview scheduling, job and candidate create/update, messaging, and analytics. `interviewer` defaults cover scoped viewing, interview listing, scorecard submission, and own availability.

#### Scenario: Recruiter creates note
- **WHEN** a recruiter with the notes action adds a note to an application
- **THEN** the note is saved

#### Scenario: Recruiter moves candidate
- **WHEN** a recruiter with `applications_move` who is also an advancer for the stage drags a candidate to a new pipeline stage
- **THEN** the candidate's stage is updated

#### Scenario: Interviewer cannot move candidate
- **WHEN** an interviewer without `applications_move` attempts to move a candidate
- **THEN** the system returns a permission error even if they are an examiner for the stage

#### Scenario: Member views analytics
- **WHEN** a recruiter navigates to the analytics page
- **THEN** the analytics page loads normally

### Requirement: Advancer-only stage advancement
The system SHALL restrict candidate advancement from a stage to assigned advancers only AND require the `applications_move` action. Both conditions must hold.

#### Scenario: Advancer advances candidate
- **WHEN** a user who is an advancer for the current stage with `applications_move` attempts to advance a candidate
- **AND** all examiners have submitted scorecards (for interview-type stages)
- **THEN** the advancement proceeds

#### Scenario: Non-advancer attempts advancement
- **WHEN** a user who is not an advancer for the current stage attempts to advance a candidate
- **THEN** the system prevents the action with a permission error

#### Scenario: Advancer without action permission attempts advancement
- **WHEN** a stage advancer lacks `applications_move` (e.g. restricted interviewer)
- **THEN** the system prevents the action with a permission error

### Requirement: Admin-only template management
The system SHALL restrict pipeline template creation, editing, and deletion to memberships passing `pipeline_manage`.

#### Scenario: Permitted user manages templates
- **WHEN** a user with `pipeline_manage` creates, edits, or deletes pipeline templates
- **THEN** the changes are applied

#### Scenario: Denied user attempts template management
- **WHEN** a user without `pipeline_manage` attempts to create, edit, or delete pipeline templates
- **THEN** the system returns a permission error

### Requirement: Admin-only audit log access
The system SHALL restrict the audit log view and audit query API to memberships passing `audit_view` (admin-only by default, not toggleable to non-admins in v1 if so configured), consistent with other permission-gated settings pages.

#### Scenario: Permitted user accesses audit log
- **WHEN** a user with `audit_view` navigates to `/:company/app/settings/audit-log` or queries audit events with a valid scope
- **THEN** the request succeeds and returns tenant-scoped audit events

#### Scenario: Denied user denied audit log access
- **WHEN** a user without `audit_view` navigates to `/:company/app/settings/audit-log` or attempts to query audit events
- **THEN** the system denies access and redirects to the dashboard with a permission-denied flash or returns a permission error for API/context calls

#### Scenario: Audit log respects workspace permissions
- **WHEN** a user is admin in tenant A but recruiter without `audit_view` in tenant B
- **THEN** the audit log is accessible only when the current workspace is tenant A, and denied when the current workspace is tenant B
