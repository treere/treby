# Candidate Portal Dashboard

## Purpose

Provide authenticated candidates with a centralized dashboard to view their applications, track status changes, and engage with recruiters through the candidate portal.

## Requirements

### Requirement: Candidate portal dashboard
The system SHALL display a dashboard at `/:tenant_slug/portal` for authenticated candidates showing their applications, summary stats, and recent messages. Each application card SHALL make the company, position, stage, and unread state immediately visible.

#### Scenario: Candidate with applications sees summary and enriched cards
- **WHEN** authenticated candidate accesses the portal dashboard
- **THEN** the system displays a summary strip with: total applications, unread messages count, and pending actions count
- **AND** a list of all their applications across all jobs, each card showing: job title, company name and logo (from tenant branding when available), location/type badges when present, current pipeline stage (with colored badge plus human-readable label, e.g., "Received" for `new`), applied date, unread indicator when the latest recruiter message is unread, and a one-line preview of the most recent message (if any)

#### Scenario: Candidate with no applications
- **WHEN** authenticated candidate accesses the portal dashboard with no applications
- **THEN** the system displays an empty state message: "You haven't applied to any positions yet" with a link to the career page

#### Scenario: Application with unread messages
- **WHEN** an application has unread messages from the recruiter
- **THEN** the application card displays an unread indicator (badge or highlight) and the message preview shows the first line of the latest unread message
- **AND** the summary strip unread count reflects the same

#### Scenario: Quick company information visible per application
- **WHEN** candidate views the dashboard
- **THEN** each application card or its expanded detail shows quick company info: tenant/company name, logo when configured, short description when available, and a "Need help? Contact ..." block only when `tenant.settings["support_email"]` or `["contact_email"]` is present (no hard-coded fallback)

### Requirement: Candidate views application details
The system SHALL allow candidates to view details of a specific application, including a clear progress panel showing where they are and what happens next, phrased in candidate-friendly language (no internal roles or blocker jargon).

#### Scenario: Application detail view
- **WHEN** candidate clicks on an application card
- **THEN** the system displays: job title, current stage (human label + badge), application date, and a timeline of status changes (system messages)

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
The system SHALL render the candidate portal with a distinct, simplified layout that is usable on mobile. The layout SHALL include an explicit Dashboard (Home) entry point in addition to the existing brand link.

#### Scenario: Portal layout with explicit Dashboard nav
- **WHEN** candidate accesses any portal route
- **THEN** the system renders a layout with: tenant branding (logo, primary color), a navigation bar with explicit links Dashboard, Messages, Schedule, Settings (in that order), and the candidate name in the header
- **AND** Dashboard points to `/:tenant_slug/portal` and is highlighted with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (with `dark:` variants) when active via `aria-current="page"`
- **AND** the tenant brand link remains and points to the same dashboard destination

#### Scenario: Mobile portal drawer includes Dashboard
- **WHEN** candidate opens the portal navigation drawer on mobile
- **THEN** the drawer shows links to Dashboard, Messages, Schedule, Settings in that order, plus candidate name and Logout, with Dashboard highlightable as active

#### Scenario: Responsive design
- **WHEN** candidate accesses the portal on a viewport <= 640px (e.g., 390px phone)
- **THEN** the layout shows a hamburger toggle that opens a drawer/overlay containing all nav links, candidate name, and Logout, with no horizontal overflow; the toggle has `aria-label` and 44px minimum touch targets, and the drawer can be dismissed via overlay or close button

### Requirement: Candidate dashboard ownership
The system SHALL enforce that a candidate can only view their own applications and tenant data.

#### Scenario: View own application detail
- **WHEN** a candidate clicks an application they own
- **THEN** the detail pane shows the job title, company context, status badge, timeline, and messages for that application

#### Scenario: Attempt to view another candidate's application
- **WHEN** a candidate tries to open an application id that does not belong to them (within same tenant or cross-tenant)
- **THEN** the system does not reveal the other application
- **AND** it shows an error or redirects without leaking existence beyond a generic not-found

#### Scenario: Tenant slug mismatch
- **WHEN** a candidate with tenant A visits `/:other_slug/portal` while authenticated
- **THEN** the system redirects to the candidate's own tenant portal slug or shows a tenant-mismatch error
- **AND** no data from the other tenant is displayed

### Requirement: Shared portal messages preload
The system SHALL provide one shared messages preload helper in the `CandidatePortal` context, and all 4 existing preload sites SHALL use it with identical assoc shape and no behavior change.

#### Scenario: All preload sites use shared helper
- **WHEN** any of the 4 portal preload sites loads messages
- **THEN** it calls the shared helper and preloads the same assocs as before

#### Scenario: Preload shape unchanged
- **WHEN** portal messages are listed via any of the 4 sites
- **THEN** returned messages carry the same preloaded assocs and ordering as before the refactor

### Requirement: Shared portal mount guard helper
The system SHALL provide portal-scoped `mount_portal/2` (tenant slug lookup plus not-found/unauthorized guard), and all 6 portal mount callbacks SHALL route through it with identical guard branches. Page titles stay inline (all 7 title strings distinct — a helper would dedup nothing).

#### Scenario: Guard branches preserved
- **WHEN** a portal view mounts with an unknown slug or unauthorized candidate session
- **THEN** the system takes the same not-found or unauthorized branch as before

#### Scenario: Title copy unchanged
- **WHEN** any portal view assigns its page title
- **THEN** the assigned title string matches the pre-refactor copy for that view
