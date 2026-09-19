## MODIFIED Requirements

### Requirement: Message queue is accessed via Settings
The system SHALL expose the Message Queue (scheduled/sent/failed/cancelled messages) under Settings → Communication, not as a top-level navigation item. The queue functionality SHALL remain unchanged.

#### Scenario: Message Queue not in top navigation
- **WHEN** a logged-in user views the top navigation
- **THEN** no "Message Queue" link is visible in the desktop bar or mobile drawer

#### Scenario: Message Queue appears under Settings Communication
- **WHEN** an admin views the Settings sidebar
- **THEN** "Message Queue" appears under the Communication group (with the same icon and subtitle as before)

#### Scenario: Queue route remains and renders inside settings shell
- **WHEN** a user navigates to `/app/messages-queue` (or `/:tenant_slug/app/messages-queue`)
- **THEN** the page renders at the same route with tabs scheduled/sent/failed/cancelled and all bulk actions (send now, cancel, retry, edit)
- **AND** when accessed via Settings the page is rendered inside the settings sidebar shell with Message Queue as active
- **AND** a direct bookmark to the route continues to work
