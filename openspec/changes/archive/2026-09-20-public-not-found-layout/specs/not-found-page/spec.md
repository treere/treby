## MODIFIED Requirements

### Requirement: Not Found page exists at a dedicated route
The system SHALL provide a public "Not Found" page served at the `/404` route, rendering a friendly, on-brand page with the public header and footer instead of the authenticated app shell, and no stacktrace.

#### Scenario: Direct visit to the 404 route
- **WHEN** a user navigates to `/404`
- **THEN** a styled "Not Found" page is displayed with the public header and footer (no app navigation or sidebar)
- **AND** no stacktrace or exception details are shown

#### Scenario: Not Found page includes a way back
- **WHEN** a user views the Not Found page
- **THEN** it offers "Browse all positions" linking to `/careers` and "Go to homepage" linking to `/`
