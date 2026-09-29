## ADDED Requirements

### Requirement: Host page refreshes after chat mutation

The system SHALL notify the host LiveView when a confirmed chat tool mutation succeeds, so the current page updates its displayed data without a manual full-page reload.

#### Scenario: Job created from chat appears in jobs list

- **WHEN** the user confirms a job creation from the chat while viewing the jobs list page
- **THEN** the new job appears in the list without a manual page reload

#### Scenario: Detail page reflects chat edits

- **WHEN** the user confirms an edit (e.g. job title) from the chat while viewing that entity's detail page
- **THEN** the detail page shows the updated values without a manual page reload

#### Scenario: Unrelated pages stay quiet

- **WHEN** a chat mutation affects an entity type the current page does not display
- **THEN** the page does not alter its list content (at most a dismissible notice when an entity link is known)

#### Scenario: Unsupported page falls back to notice

- **WHEN** the current page has no live-refresh handling for the changed entity
- **THEN** the user sees a short text notice naming the changed entity (flash messages render text only, so no link is embedded) instead of silent staleness

### Requirement: Tenant- and user-scoped refresh signal

The system SHALL scope the refresh signal to the acting user inside the acting tenant, and pages SHALL ignore signals for other users.

#### Scenario: Signal isolation

- **WHEN** a chat mutation completes for user A in tenant T
- **THEN** only user A's LiveViews in tenant T refresh; other users and tenants see no change

### Requirement: Refresh reads committed data

The system SHALL broadcast the refresh signal only after the mutation is committed, and refreshing pages SHALL re-read from the database (re-running the page's current query/filter where applicable).

#### Scenario: Filtered list stays consistent

- **WHEN** a filtered jobs list receives a refresh for a job outside the current filter
- **THEN** the list does not show the excluded job
