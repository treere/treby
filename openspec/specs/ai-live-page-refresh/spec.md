# AI Live Page Refresh

## Purpose

Refresh the current page live when a confirmed assistant action mutates an entity, so users see results without reloading.

## Requirements

### Requirement: Host page refreshes after assistant mutation
The system SHALL notify the host LiveView when a confirmed assistant mutation succeeds, scoped to the acting user inside the acting tenant. Pages displaying the entity SHALL re-read committed data; covered pages SHALL show a flash notice for entity types they do not display.

#### Scenario: Job created from chat appears in jobs list
- **WHEN** the user confirms a job creation from the chat while viewing the jobs list
- **THEN** the new job appears in the list without a manual page reload

#### Scenario: Detail page reflects chat edits
- **WHEN** the user confirms an edit while viewing that entity's detail page
- **THEN** the detail page shows the updated values without a manual reload

#### Scenario: Unrelated views stay quiet
- **WHEN** a mutation affects an entity type the current view does not display
- **THEN** the view does not alter its listed content

#### Scenario: Signal isolation
- **WHEN** a mutation completes for one user in one tenant
- **THEN** only that user's views in that tenant refresh; other users see no change

### Requirement: Refresh reads committed data
The system SHALL broadcast the refresh signal only after the mutation is committed, and refreshing pages SHALL re-read from the database, re-running the page's current query and filter where applicable.

#### Scenario: Filtered list stays consistent
- **WHEN** a filtered list receives a refresh for an entity outside the current filter
- **THEN** the list does not show the excluded entity
