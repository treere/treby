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
The system SHALL allow candidates to view details of a specific application.

#### Scenario: Application detail view
- **WHEN** candidate clicks on an application card
- **THEN** the system displays: job title, current stage, application date, source, and a timeline of status changes (system messages)

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
