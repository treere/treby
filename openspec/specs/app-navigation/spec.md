# App Navigation

## Purpose

Define the main application navigation including desktop nav bar, mobile drawer, active link highlighting, and navigation items.

## Requirements
### Requirement: Navigation includes all key features
The app navigation SHALL display primary links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant, with utilities (notifications, Settings gear, user menu) separate. Import and Message Queue SHALL NOT appear as top-level navigation items. The brand logo link to home remains but is not the only home affordance.

#### Scenario: Desktop nav shows trimmed primary links with explicit Home
- **WHEN** a logged-in user views the navigation bar at 1280px width or wider
- **THEN** inline links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant are visible in that order
- **AND** Home points to `/:tenant_slug/app` and each primary link points to `/:tenant_slug/app/...` (e.g. `/acme/app/jobs`) when a tenant is present, falling back to `/app/...` only when no tenant is assigned, and has `data-nav="/app"` with `aria-current="page"` when active
- **AND** Import is not visible in the top bar
- **AND** Message Queue is not visible in the top bar
- **AND** a gear icon for Settings is visible for all authenticated users (next to the notification bell), with `aria-label` "Settings"

#### Scenario: Mobile drawer shows trimmed primary links with explicit Home
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant are visible
- **AND** Import and Message Queue are not visible as top-level items
- **AND** the Settings gear is visible for all authenticated users

#### Scenario: Active Home link is highlighted
- **WHEN** a user is on the app home/dashboard (`/app` or `/:tenant_slug/app`)
- **THEN** the Home nav link displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (and `dark:bg-zinc-800 dark:text-zinc-100`)
- **AND** all other nav links display with muted styling

#### Scenario: Brand logo remains as home affordance
- **WHEN** a logged-in user clicks the Treby brand text in the header
- **THEN** the app navigates to `/:tenant_slug/app` (or `/app` when no tenant) — same destination as the explicit Home link

#### Scenario: Settings landing page uses grouped sidebar
- **WHEN** a user navigates to `/app/settings` (or `/:tenant_slug/app/settings`)
- **THEN** the page renders a grouped sidebar with five sections (Organization, Hiring Process, Communication, Scheduling, Privacy & System) instead of a flat grid
- **AND** the top navigation still contains a single Settings entry point as a gear icon for all users, leading to a filtered hub for members and full hub for admins

### Requirement: Header utilities are unified under a user menu
The top navigation SHALL group theme, language, and logout into a single user dropdown triggered by the user name/avatar, instead of scattering them as separate header controls.

#### Scenario: Desktop header has unified user menu
- **WHEN** a logged-in user views the desktop header
- **THEN** a single control showing the user name/avatar with `▾` is visible on the right
- **AND** clicking it reveals a dropdown containing identity (name + role), Theme control (System/Light/Dark), Language (EN/IT), and Logout
- **AND** standalone theme and language controls are not visible in the header outside the dropdown

#### Scenario: Mobile drawer mirrors unified user menu
- **WHEN** a user opens the mobile navigation drawer
- **THEN** the drawer bottom section shows the same unified user area with Theme, Language, and Logout, plus the Settings gear

### Requirement: Active link is visually highlighted
The navigation SHALL visually distinguish the link corresponding to the user's current page using the Modern SaaS Minimal active language: `bg-zinc-100 text-zinc-900 rounded-md font-medium` (with `dark:bg-zinc-800`) rather than a blue bottom border.

#### Scenario: Desktop active link highlighting
- **WHEN** a user is on the Candidates page (`/app/candidates`)
- **THEN** the Candidates nav link displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (and `dark:bg-zinc-800 dark:text-zinc-100`)
- **AND** all other nav links display with `text-zinc-500 hover:text-zinc-900 hover:bg-zinc-50 rounded-md font-normal`

#### Scenario: Mobile active link highlighting
- **WHEN** a user is on the Analytics page (`/app/analytics`)
- **THEN** the Analytics link in the mobile drawer displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium`
- **AND** all other mobile drawer links display with normal muted styling

### Requirement: Mobile drawer includes logout and locale
The mobile navigation drawer SHALL include a logout link and a locale switcher, matching the desktop nav.

#### Scenario: Mobile drawer has logout
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a Logout link is visible at the bottom of the drawer

#### Scenario: Mobile drawer has locale switcher
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a locale switcher (EN/IT) is visible in the drawer

### Requirement: Mobile drawer includes theme toggle
The mobile navigation drawer SHALL include a theme toggle alongside the locale switcher.

#### Scenario: Mobile drawer has theme toggle
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a theme toggle control is visible next to the locale switcher

### Requirement: Unauthenticated pages include theme and locale toggles
The homepage, login, register, and forgot password pages SHALL include the theme toggle and locale switcher.

#### Scenario: Homepage has toggles
- **WHEN** a user views the homepage
- **THEN** a theme toggle control and locale switcher are visible in the header

#### Scenario: Login page has toggles
- **WHEN** a user views the login page
- **THEN** a theme toggle control and locale switcher are visible
- **AND** both controls function without requiring a signed-in session

### Requirement: App navigation uses SaaS minimal header
The app navigation header SHALL use the Modern SaaS Minimal header language: sticky translucent `bg-white/80 supports-[backdrop-filter]:bg-white/80 backdrop-blur border-b border-zinc-200` (light) / `bg-zinc-900/80 border-zinc-800` (dark), with nav links as `rounded-md` pills and hover `bg-zinc-50`.

#### Scenario: Desktop header is translucent and minimal
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** the header has `sticky top-0 bg-white/80 backdrop-blur border-b border-zinc-200` (light) and links are `px-3 py-1.5 rounded-md text-sm font-medium text-zinc-500 hover:text-zinc-900 hover:bg-zinc-50`

#### Scenario: Page background is SaaS minimal
- **WHEN** a user views any app page
- **THEN** the outer page wrapper uses `bg-zinc-50` (light) / `bg-zinc-900` (dark) — not `bg-base-200`
