## MODIFIED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display links to all key features on screens at or above `xl` (1280px): Jobs, Candidates, Assistant, Import, Interviews, Analytics, Message Queue, and Settings (admin only). Below `xl` the same links are available inside the slide-out drawer.

#### Scenario: Inline nav shows all links at xl
- **WHEN** a logged-in user views the navigation bar at 1280px or wider
- **THEN** inline links to Jobs, Candidates, Assistant, Import, Interviews, Analytics, and Message Queue are visible
- **AND** the Settings link is visible only if the user has admin role

#### Scenario: Drawer shows all links below xl
- **WHEN** a logged-in user opens the navigation drawer below 1280px
- **THEN** links to all key features are visible in the drawer
- **AND** the Settings link is visible only if the user has admin role

### Requirement: Active link is visually highlighted
The navigation SHALL visually distinguish the link corresponding to the user's current page using the Modern SaaS Minimal active language: `bg-zinc-100 text-zinc-900 rounded-md font-medium` (with `dark:bg-zinc-800`) rather than a blue bottom border. This applies to both the inline nav (≥xl) and the drawer (<xl).

#### Scenario: Desktop active link highlighting
- **WHEN** a user is on the Candidates page at 1280px or wider
- **THEN** the Candidates nav link displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium` (and `dark:bg-zinc-800 dark:text-zinc-100`)

#### Scenario: Drawer active link highlighting
- **WHEN** a user is on the Analytics page and opens the drawer below 1280px
- **THEN** the Analytics link in the drawer displays with `bg-zinc-100 text-zinc-900 rounded-md font-medium`
- **AND** all other drawer links display with normal muted styling
