## ADDED Requirements

### Requirement: Script exists for automated screenshot capture
The project SHALL include a Playwright-based script that starts the Phoenix app, navigates key pages, and captures screenshots.

#### Scenario: Script exists at scripts/screenshots.mjs
- **WHEN** a developer runs `node scripts/screenshots.mjs`
- **THEN** the script starts the Phoenix dev server, waits for it to be ready, and proceeds

### Requirement: Script logs in as demo user
The screenshot script SHALL authenticate as the seeded admin user before capturing authenticated pages.

#### Scenario: Login succeeds
- **WHEN** the script navigates to the login page
- **THEN** it fills in admin@acme.com / password123 and submits, then verifies the dashboard is visible

### Requirement: Script captures all major pages
The screenshot script SHALL capture every major page of the application with consistent viewport and timing.

#### Scenario: Screenshots are generated
- **WHEN** the script runs to completion
- **THEN** PNG files are saved to `site/public/screenshots/` for: login, dashboard, jobs list, pipeline kanban, candidates list, candidate detail, analytics, settings hub, pipeline settings, team settings, custom fields, branding, public careers, public job detail, apply form, register page, add note form, add candidate form, job detail

#### Scenario: Consistent viewport
- **WHEN** capturing each screenshot
- **THEN** the viewport is 1280x900 pixels, and the script waits for `networkidle` before capturing

### Requirement: Script cleans up after itself
The screenshot script SHALL stop the Phoenix server when done, even if an error occurred.

#### Scenario: Server cleanup
- **WHEN** the script finishes or encounters an error
- **THEN** the Phoenix server process is killed
