## MODIFIED Requirements

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
