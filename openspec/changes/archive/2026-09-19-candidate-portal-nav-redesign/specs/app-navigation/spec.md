## MODIFIED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display primary links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant, with utilities (notifications, Settings gear, user menu) separate. Import and Message Queue SHALL NOT appear as top-level navigation items. The brand logo link to home remains but is not the only home affordance.

#### Scenario: Desktop nav shows trimmed primary links with explicit Home
- **WHEN** a logged-in user views the navigation bar at 1280px width or wider
- **THEN** inline links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant are visible in that order
- **AND** Home points to `/:tenant_slug/app` (or `/app` when no tenant) and has `data-nav="/app"` with `aria-current="page"` when active
- **AND** Import is not visible in the top bar
- **AND** Message Queue is not visible in the top bar
- **AND** a gear icon for Settings is visible only if the user has admin role (next to the notification bell), with `aria-label` "Settings"

#### Scenario: Mobile drawer shows trimmed primary links with explicit Home
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant are visible
- **AND** Import and Message Queue are not visible as top-level items
- **AND** the Settings gear is visible only if the user has admin role

#### Scenario: Settings landing page uses grouped sidebar
- **WHEN** a user navigates to `/app/settings` (or `/:tenant_slug/app/settings`)
- **THEN** the page renders a grouped sidebar with five sections (Organization, Hiring Process, Communication, Scheduling, Privacy & System) instead of a flat grid
- **AND** the top navigation still contains a single Settings entry point as a gear icon (admin) or via the filtered hub for members

#### Scenario: Active Home link is highlighted
- **WHEN** a user is on the app home/dashboard (`/app` or `/:tenant_slug/app`)
- **THEN** the Home nav link displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (and `dark:bg-zinc-800 dark:text-zinc-100`)
- **AND** all other nav links display with muted styling

#### Scenario: Brand logo remains as home affordance
- **WHEN** a logged-in user clicks the Treby brand text in the header
- **THEN** the app navigates to `/:tenant_slug/app` (or `/app`) — same destination as the explicit Home link
