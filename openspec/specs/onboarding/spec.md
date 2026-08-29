# Onboarding

## Purpose

Guide new users through initial setup steps (create job, add candidate, invite team, customize career page) via a dashboard checklist and smart empty states across all pages.

## Requirements

### Requirement: Onboarding checklist displayed on dashboard
The system SHALL display an onboarding checklist on the dashboard when the user has not completed all setup steps and has not permanently dismissed it.

#### Scenario: New user sees checklist
- **WHEN** a user with no jobs, no candidates, no additional team members, and no branding visits the dashboard
- **THEN** an onboarding checklist is displayed between the welcome header and stat cards
- **AND** the checklist shows 4 steps: create job, add candidate, invite team, customize career page
- **AND** each step shows a completion indicator (checkmark when done, empty circle when not)
- **AND** a progress bar shows the percentage of completed steps

#### Scenario: User with some steps completed
- **WHEN** a user has created a job but has no candidates, no additional team, and no branding
- **THEN** the checklist shows 1/4 steps complete
- **AND** the "Create a job posting" step shows a checkmark and strikethrough styling
- **AND** the progress bar shows 25%

#### Scenario: All steps completed
- **WHEN** a user has created at least one job, added at least one candidate, invited at least one team member, and configured career page branding
- **THEN** the onboarding checklist is not rendered (hidden automatically)

### Requirement: Onboarding step links
Each onboarding step SHALL be a clickable link that navigates to the relevant page for completing that step.

#### Scenario: Clicking a step navigates to correct page
- **WHEN** the user clicks the "Create a job posting" step
- **THEN** the user is navigated to the jobs page (`/app/jobs`)

#### Scenario: Completed steps link to view
- **WHEN** a step is marked as complete and the user clicks it
- **THEN** the user is navigated to the relevant page (same destination as incomplete steps)

### Requirement: Onboarding checklist dismissal
The system SHALL allow users to dismiss the onboarding checklist.

#### Scenario: Session dismiss via close button
- **WHEN** the user clicks the dismiss (X) button on the checklist
- **THEN** the checklist is hidden for the current page load
- **AND** the checklist reappears on the user's next login or page refresh

#### Scenario: Permanent dismiss via "Don't show again"
- **WHEN** the user clicks the "Don't show again" link on the checklist
- **THEN** the checklist is permanently hidden for this user across all sessions and devices
- **AND** a `onboarding_checklist_dismissed` flag is persisted to the user's database record

### Requirement: Onboarding completion tracking via live state
The system SHALL determine onboarding step completion by querying actual tenant data rather than a stored flag.

#### Scenario: Job creation step completion
- **WHEN** the tenant has at least one job posting
- **THEN** the "Create a job posting" step is marked as complete

#### Scenario: Candidate addition step completion
- **WHEN** the tenant has at least one candidate
- **THEN** the "Add your first candidate" step is marked as complete

#### Scenario: Team invitation step completion
- **WHEN** the tenant has at least one team member other than the current user
- **THEN** the "Invite your team" step is marked as complete

#### Scenario: Career page branding step completion
- **WHEN** the tenant has configured career page branding (title, color, or logo)
- **THEN** the "Customize your career page" step is marked as complete

### Requirement: Shared empty state component
The system SHALL provide a reusable empty state component for display when a list or collection is empty.

#### Scenario: Empty state with action
- **WHEN** a page has no items to display and an action is provided
- **THEN** the empty state renders with an icon, title, descriptive text, and a call-to-action link/button

#### Scenario: Empty state without action
- **WHEN** a page has no items to display and no action is provided
- **THEN** the empty state renders with an icon, title, and descriptive text only (no button)

### Requirement: Dashboard empty state for new users
The system SHALL display a welcoming empty state on the dashboard when no data exists, guiding the user toward their first action.

#### Scenario: Empty dashboard greeting
- **WHEN** a new user with no jobs, no interviews, and no candidates visits the dashboard
- **THEN** a welcome message is displayed explaining that the dashboard will come to life after creating jobs and adding candidates
- **AND** a prominent "Create your first job" call-to-action button is shown
- **AND** the onboarding checklist is shown above the stat cards

#### Scenario: Dashboard with partial data
- **WHEN** a user has some data (e.g., jobs but no interviews)
- **THEN** the stat cards show actual counts (not zero-state guidance)
- **AND** sections with no data show the standard empty state component (not the onboarding greeting)

### Requirement: Jobs page empty state
The system SHALL display a guided empty state on the jobs page when no jobs exist.

#### Scenario: No jobs exist
- **WHEN** a user visits the jobs page and the tenant has no job postings
- **THEN** an empty state is displayed with an icon, title ("No job postings yet"), a brief description explaining what job postings do, and a "Create your first job" button

#### Scenario: Create first job from empty state
- **WHEN** a user with no job postings clicks the "Create your first job" button on the jobs page empty state
- **THEN** the inline job creation form is revealed on the page so the user can create their first job

### Requirement: Candidates page empty state
The system SHALL display a guided empty state on the candidates page when no candidates exist.

#### Scenario: No candidates exist
- **WHEN** a user visits the candidates page and the tenant has no candidates
- **THEN** an empty state is displayed with an icon, title ("No candidates yet"), a brief description explaining how to add candidates (manual, CSV import, career page), and buttons for "Add a candidate" and "Import from CSV"
