# App Navigation

## Delta

### MODIFIED Requirements

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

### MODIFIED Requirements

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
