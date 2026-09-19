## MODIFIED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display primary links to Jobs, Candidates, Interviews, Analytics, and Assistant, with utilities (notifications, Settings gear, user menu) separate. Import and Message Queue SHALL NOT appear as top-level navigation items.

#### Scenario: Desktop nav shows trimmed primary links
- **WHEN** a logged-in user views the navigation bar at 1280px width or wider
- **THEN** inline links to Jobs, Candidates, Interviews, Analytics, and Assistant are visible in that order
- **AND** Import is not visible in the top bar
- **AND** Message Queue is not visible in the top bar
- **AND** a gear icon for Settings is visible only if the user has admin role (next to the notification bell), with `aria-label` "Settings"

#### Scenario: Mobile drawer shows trimmed primary links
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Jobs, Candidates, Interviews, Analytics, and Assistant are visible
- **AND** Import and Message Queue are not visible as top-level items
- **AND** the Settings gear is visible only if the user has admin role

#### Scenario: Settings landing page uses grouped sidebar
- **WHEN** a user navigates to `/app/settings` (or `/:tenant_slug/app/settings`)
- **THEN** the page renders a grouped sidebar with five sections (Organization, Hiring Process, Communication, Scheduling, Privacy & System) instead of a flat grid
- **AND** the top navigation still contains a single Settings entry point as a gear icon (admin) or via the filtered hub for members

### Requirement: Header utilities are unified under a user menu
The top navigation SHALL group theme, language, and logout into a single user dropdown triggered by the user name/avatar, instead of scattering them as separate header controls.

#### Scenario: Desktop header has unified user menu
- **WHEN** a logged-in user views the desktop header
- **THEN** a single control showing the user name/avatar with `▾` is visible on the right
- **AND** clicking it reveals a dropdown containing identity (name + role), Theme control (System/Light/Dark), Language (EN/IT), and Logout
- **AND** standalone theme and language controls are not visible in the header outside the dropdown

#### Scenario: Mobile drawer mirrors unified user menu
- **WHEN** a user opens the mobile navigation drawer
- **THEN** the drawer bottom section shows the same unified user area with Theme, Language, and Logout, plus the Settings gear if admin
