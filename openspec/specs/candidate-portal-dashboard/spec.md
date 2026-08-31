# Candidate Portal Dashboard

## Purpose

Provide authenticated candidates with a centralized dashboard to view their applications, track status changes, and engage with recruiters through the candidate portal.

## Requirements

### Requirement: Candidate portal dashboard
The system SHALL display a dashboard at `/:tenant_slug/portal` for authenticated candidates showing their applications and recent messages.

#### Scenario: Candidate with applications
- **WHEN** authenticated candidate accesses the portal dashboard
- **THEN** the system displays a list of all their applications across all jobs, each showing: job title, current pipeline stage (with colored badge), last activity timestamp, and a preview of the most recent message (if any)

#### Scenario: Candidate with no applications
- **WHEN** authenticated candidate accesses the portal dashboard with no applications
- **THEN** the system displays an empty state message: "You haven't applied to any positions yet" with a link to the career page

#### Scenario: Application with unread messages
- **WHEN** an application has unread messages from the recruiter
- **THEN** the application card displays an unread indicator (badge or highlight) and the message preview shows the first line of the latest unread message

### Requirement: Candidate views application details
The system SHALL allow candidates to view details of a specific application, including a clear progress panel showing where they are and what happens next, phrased in candidate-friendly language (no internal roles or blocker jargon).

#### Scenario: Application detail view
- **WHEN** candidate clicks on an application card
- **THEN** the system displays: job title, current stage, application date, source, and a timeline of status changes (system messages)

#### Scenario: Progress panel shows current step and what is next
- **WHEN** candidate views an application with no action pending on them
- **THEN** the progress panel shows their current step and the next step in the process (e.g. "You are scheduled for an interview", "Your application is under review")
- **AND** the panel does not reveal internal roles or internal blocker details

#### Scenario: Progress panel surfaces a pending action for the candidate
- **WHEN** candidate views an application
- **AND** there is an action pending on the candidate (e.g. replying to a request for more information, or choosing an interview time slot)
- **THEN** the progress panel highlights that action as pending on the candidate and links to where they can complete it

#### Scenario: Application with active conversation
- **WHEN** candidate views an application that has an active conversation
- **THEN** the system displays the conversation thread with all messages and a reply form at the bottom

### Requirement: Candidate portal layout
The system SHALL render the candidate portal with a distinct, simplified layout.

#### Scenario: Portal layout
- **WHEN** candidate accesses any portal route
- **THEN** the system renders a layout with: tenant branding (logo, primary color), a simple navigation (Dashboard, Settings), and the candidate name in the header

#### Scenario: Responsive design
- **WHEN** candidate accesses the portal on a mobile device
- **THEN** the layout adapts to mobile with a hamburger menu and stacked application cards

### Requirement: Candidate dashboard ownership
The system SHALL enforce that a candidate can only view their own applications and tenant data.

#### Scenario: View own application detail
- **WHEN** a candidate clicks an application they own
- **THEN** the detail pane shows the job title, status badge, timeline, and messages for that application

#### Scenario: Attempt to view another candidate's application
- **WHEN** a candidate tries to open an application id that does not belong to them (within same tenant or cross-tenant)
- **THEN** the system does not reveal the other application
- **AND** it shows an error or redirects without leaking existence beyond a generic not-found

#### Scenario: Tenant slug mismatch
- **WHEN** a candidate with tenant A visits `/:other_slug/portal` while authenticated
- **THEN** the system redirects to the candidate's own tenant portal slug or shows a tenant-mismatch error
- **AND** no data from the other tenant is displayed
