# Role-Based Access Control

## Purpose

Enforce admin vs member permissions across all LiveViews and context functions so that only admins can configure the system while members can perform day-to-day hiring actions.

## Requirements

### Requirement: Admin-only settings access
The system SHALL restrict settings pages to admin users only.

#### Scenario: Admin accesses settings
- **WHEN** an admin navigates to any `/app/settings/*` page
- **THEN** the page loads normally

#### Scenario: Member accesses settings
- **WHEN** a member navigates to any `/app/settings/*` page
- **THEN** the system redirects to the dashboard with a "permission denied" flash message

### Requirement: Admin-only team management
The system SHALL restrict team invitations and removals to admin users.

#### Scenario: Admin invites team member
- **WHEN** an admin sends a team invitation
- **THEN** the invitation is created and emailed

#### Scenario: Member attempts to invite
- **WHEN** a member attempts to invite a team member
- **THEN** the system returns a permission error

#### Scenario: Admin removes team member
- **WHEN** an admin removes a team member
- **THEN** the member is removed from the tenant

#### Scenario: Member attempts to remove
- **WHEN** a member attempts to remove a team member
- **THEN** the system returns a permission error

### Requirement: Admin-only pipeline configuration
The system SHALL restrict pipeline stage management to admin users.

#### Scenario: Admin manages pipeline stages
- **WHEN** an admin creates, edits, reorders, or deletes pipeline stages
- **THEN** the changes are applied

#### Scenario: Member attempts pipeline configuration
- **WHEN** a member attempts to create, edit, or delete pipeline stages
- **THEN** the system returns a permission error

### Requirement: Admin-only custom field management
The system SHALL restrict custom field management to admin users.

#### Scenario: Admin manages custom fields
- **WHEN** an admin creates, edits, or deletes custom fields
- **THEN** the changes are applied

#### Scenario: Member attempts custom field management
- **WHEN** a member attempts to create, edit, or delete custom fields
- **THEN** the system returns a permission error

### Requirement: Admin-only candidate deletion
The system SHALL restrict candidate deletion to admin users.

#### Scenario: Admin deletes candidate
- **WHEN** an admin deletes a candidate
- **THEN** the candidate is removed

#### Scenario: Member attempts deletion
- **WHEN** a member attempts to delete a candidate
- **THEN** the system returns a permission error

### Requirement: Admin-only email template and scorecard management
The system SHALL restrict email template and scorecard template management to admin users.

#### Scenario: Admin manages templates
- **WHEN** an admin creates, edits, or deletes email templates or scorecard templates
- **THEN** the changes are applied

#### Scenario: Member attempts template management
- **WHEN** a member attempts to manage email templates or scorecard templates
- **THEN** the system returns a permission error

### Requirement: Member permissions
The system SHALL allow members to perform day-to-day hiring actions.

#### Scenario: Member creates note
- **WHEN** a member adds a note to an application
- **THEN** the note is saved

#### Scenario: Member moves candidate
- **WHEN** a member drags a candidate to a new pipeline stage
- **THEN** the candidate's stage is updated

#### Scenario: Member schedules interview
- **WHEN** a member schedules an interview
- **THEN** the interview is booked and notifications are sent

#### Scenario: Member creates job
- **WHEN** a member creates a new job posting
- **THEN** the job is created

#### Scenario: Member views analytics
- **WHEN** a member navigates to the analytics page
- **THEN** the analytics page loads normally
