## MODIFIED Requirements

### Requirement: Navigation includes all key features
The app navigation SHALL display primary links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant, with utilities (notifications, Settings gear, user menu) separate. Import and Message Queue SHALL NOT appear as top-level navigation items.

#### Scenario: Desktop nav shows trimmed primary links with explicit Home
- **WHEN** a logged-in user views the navigation bar at 1280px width or wider
- **THEN** inline links to Home, Jobs, Candidates, Interviews, Analytics, and Assistant are visible in that order
- **AND** Home points to `/:tenant_slug/app` and each primary link points to `/:tenant_slug/app/...` (e.g. `/acme/app/jobs`) when a tenant is present, falling back to `/app/...` only when no tenant is assigned
- **AND** Import is not visible in the top bar
- **AND** Message Queue is not visible in the top bar

#### Scenario: Brand logo remains as home affordance
- **WHEN** a logged-in user clicks the Treby brand text in the header
- **THEN** the app navigates to `/:tenant_slug/app` (or `/app` when no tenant) — same destination as the explicit Home link
