## ADDED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display links to all key features: Jobs, Candidates, Pipeline, Import, Compare, Interviews, Analytics, and Settings (admin only).

#### Scenario: Desktop nav shows all links
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** links to Jobs, Candidates, Pipeline, Import, Compare, Interviews, and Analytics are visible
- **AND** the Settings link is visible only if the user has admin role

#### Scenario: Mobile drawer shows all links
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Jobs, Candidates, Pipeline, Import, Compare, Interviews, and Analytics are visible
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

#### Scenario: Sub-route highlights parent link
- **WHEN** a user is on a pipeline detail page (`/app/pipeline/123`)
- **THEN** the Pipeline nav link is highlighted as active

### Requirement: Mobile drawer includes logout and locale
The mobile navigation drawer SHALL include a logout link and a locale switcher, matching the desktop nav.

#### Scenario: Mobile drawer has logout
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a Logout link is visible at the bottom of the drawer

#### Scenario: Mobile drawer has locale switcher
- **WHEN** a user opens the mobile navigation drawer
- **THEN** a locale switcher (EN/IT) is visible in the drawer
