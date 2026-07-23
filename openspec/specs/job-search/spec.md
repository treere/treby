# Job Search

## Purpose

Provide text-based search for jobs on both the global and per-tenant career boards.

## Requirements

### Requirement: Search on global board
The system SHALL provide a search input on the global job board to filter positions by text.

#### Scenario: Search input present
- **WHEN** a visitor views the global board at `/careers`
- **THEN** a search input field is visible

#### Scenario: Search by title
- **WHEN** a visitor types "developer" and submits the search
- **THEN** only jobs with "developer" in the title are shown

#### Scenario: Search by description
- **WHEN** a visitor types "elixir" and submits the search
- **THEN** only jobs with "elixir" in the title or description are shown

#### Scenario: Search with no results
- **WHEN** a search yields no matching jobs
- **THEN** the page displays "No positions match your search"

#### Scenario: Clear search
- **WHEN** a visitor clears the search input and submits
- **THEN** all visible open positions are shown again

### Requirement: Search on tenant board
The system SHALL provide a search input on the per-tenant career page to filter positions by text.

#### Scenario: Search input present
- **WHEN** a visitor views `/:tenant_slug/careers`
- **THEN** a search input field is visible

#### Scenario: Search within tenant
- **WHEN** a visitor searches for "engineer" on a tenant's career page
- **THEN** only jobs from that tenant matching "engineer" in title or description are shown
