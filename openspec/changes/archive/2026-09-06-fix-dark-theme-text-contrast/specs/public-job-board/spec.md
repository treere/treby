## MODIFIED Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions across all tenants. The board SHALL include the same public header as tenant career pages: a homepage link (Treby brand → `/`) on the left and theme toggle + language switcher on the right, both contrast-compliant in dark mode.

#### Scenario: Global board loads
- **WHEN** a visitor navigates to `/careers`
- **THEN** the page displays all open jobs with `visible=true` from all tenants
- **AND** a header bar with homepage link and theme + language controls is visible at the top

#### Scenario: Each job shows company info
- **WHEN** the global board loads
- **THEN** each job listing shows the company logo, company name, job title, and salary range

#### Scenario: No visible jobs
- **WHEN** there are no visible open positions across any tenant
- **THEN** the page displays "No open positions available"

#### Scenario: Global board header in dark mode
- **WHEN** a visitor opens `http://localhost:4000/careers` in dark mode with any locale
- **THEN** the homepage/brand link and the theme+language controls are visible with ≥4.5:1 contrast on their `bg-white/80 dark:bg-zinc-900/80` header and no axe `color-contrast` violation is reported

