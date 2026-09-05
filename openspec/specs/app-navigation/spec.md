# App Navigation

## Purpose

Define the main application navigation including desktop nav bar, mobile drawer, active link highlighting, and navigation items.
## Requirements
### Requirement: Navigation includes all key features
The app navigation SHALL display links to all key features: Jobs, Candidates, Import, Interviews, Analytics, and Settings (admin only).

#### Scenario: Desktop nav shows all links
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** links to Jobs, Candidates, Import, Interviews, and Analytics are visible
- **AND** the Settings link is visible only if the user has admin role

#### Scenario: Mobile drawer shows all links
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Jobs, Candidates, Import, Interviews, and Analytics are visible
- **AND** the Settings link is visible only if the user has admin role

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

