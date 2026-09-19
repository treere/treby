## MODIFIED Requirements

### Requirement: Candidate import is discoverable from the Candidates page
The system SHALL expose candidate CSV import from the Candidates page header (and empty state), not as a top-level navigation item. The import flow and route SHALL remain unchanged.

#### Scenario: Candidates header shows Import button
- **WHEN** a user views `/app/candidates` (or `/:tenant_slug/app/candidates`) with or without existing candidates
- **THEN** a secondary button "Import CSV" (with `hero-arrow-up-tray` icon) is visible in the page header beside "Add Candidate"
- **AND** clicking it navigates to `/app/import` (or `/:tenant_slug/app/import`)

#### Scenario: Import not in top navigation
- **WHEN** a logged-in user views the top navigation
- **THEN** no "Import" link is visible in the desktop bar or mobile drawer

#### Scenario: Import route and breadcrumb remain
- **WHEN** a user navigates to `/app/import`
- **THEN** the page renders at the same route with breadcrumb `Candidates > Import` and the existing 4-step flow (Upload → Map → Preview → Import)
- **AND** a direct bookmark to `/app/import` continues to work
