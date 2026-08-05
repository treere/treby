## MODIFIED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display links to all key features: Jobs, Candidates, Pipeline, Import, Interviews, Analytics, and Settings (admin only).

#### Scenario: Desktop nav shows all links
- **WHEN** a logged-in user views the desktop navigation bar
- **THEN** links to Jobs, Candidates, Pipeline, Import, Interviews, and Analytics are visible
- **AND** the Settings link is visible only if the user has admin role

#### Scenario: Mobile drawer shows all links
- **WHEN** a logged-in user opens the mobile navigation drawer
- **THEN** links to Jobs, Candidates, Pipeline, Import, Interviews, and Analytics are visible
- **AND** the Settings link is visible only if the user has admin role
