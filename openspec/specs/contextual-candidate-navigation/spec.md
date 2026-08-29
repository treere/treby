# Contextual Candidate Navigation

## Purpose

Preserve the user's context when navigating from a job page or Kanban board into a candidate profile, so the back link returns to where they came from instead of always dropping them into the full candidate list.

## Requirements

### Requirement: Back link honors return origin
The system SHALL display a back link on the candidate profile page that returns to the originating page when a return origin is provided.

#### Scenario: Return to job page
- **WHEN** a user navigates to a candidate profile from a job detail page
- **THEN** the back link returns to the originating job detail page

#### Scenario: Return to Kanban
- **WHEN** a user navigates to a candidate profile from a Kanban board
- **THEN** the back link returns to that job's pipeline board

#### Scenario: Default back link
- **WHEN** a user navigates to a candidate profile directly or without a return origin
- **THEN** the back link defaults to the candidates list

### Requirement: Return origin validation
The system SHALL only honor return origins that point to internal application paths.

#### Scenario: Invalid return origin
- **WHEN** a candidate profile is opened with an invalid or external return path
- **THEN** the back link falls back to the candidates list