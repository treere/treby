# App Navigation

## Purpose

Define the main application navigation including desktop nav bar, mobile drawer, active link highlighting, and navigation items.

## Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display links to all key features: Jobs, Candidates, Import, Interviews, Analytics, and Settings (admin only). The Pipeline link is removed from the navigation; pipeline boards are reached from individual job pages.

#### Scenario: Desktop nav shows all links
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** links to Jobs, Candidates, Import, Interviews, and Analytics are visible
- **AND** no top-level Pipeline link is shown
- **AND** the Settings link is visible only if the user has admin role

#### Scenario: Mobile drawer shows all links
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Jobs, Candidates, Import, Interviews, and Analytics are visible
- **AND** no top-level Pipeline link is shown
- **AND** the Settings link is visible only if the user has admin role

### Requirement: Active link is visually highlighted
The navigation SHALL visually distinguish the link corresponding to the user's current page.

#### Scenario: Desktop active link highlighting
- **WHEN** a user is on the Candidates page (`/app/candidates`)
- **THEN** the Candidates nav link displays with a blue bottom border and bold text
- **AND** all other nav links display with no border and normal weight

#### Scenario: Mobile active link highlighting
- **WHEN** a user is on the Analytics page (`/app/analytics`)
- **THEN** the Analytics link in the mobile drawer displays with a distinct active style (blue text or background)
- **AND** all other mobile drawer links display with normal styling

#### Scenario: Pipeline detail pages have no nav highlight
- **WHEN** a user is on a pipeline detail page (`/app/pipeline/123`)
- **THEN** no Pipeline nav link is highlighted because the top-level Pipeline nav item no longer exists

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
