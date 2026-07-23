# Application Review State

## Purpose

Let hiring managers quickly see which candidates they've already looked at versus new applicants, so nothing falls through the cracks.

## Requirements

### Requirement: Review indicator on pipeline cards
The system SHALL show a visual indicator for unreviewed applications on the pipeline Kanban board.

#### Scenario: New application badge
- **WHEN** a candidate has an application with `reviewed = false`
- **THEN** a "NEW" badge is shown on their card in the pipeline view

#### Scenario: Reviewed application
- **WHEN** a candidate has an application with `reviewed = true`
- **THEN** no badge is shown on their card

### Requirement: Toggle review state
The system SHALL allow marking applications as reviewed or unreviewed with a single click.

#### Scenario: Mark as reviewed
- **WHEN** a user clicks the review toggle on a pipeline card
- **THEN** the application's `reviewed` field is set to `true`
- **AND** the "NEW" badge disappears

#### Scenario: Mark as unreviewed
- **WHEN** a user clicks the review toggle on a reviewed application
- **THEN** the application's `reviewed` field is set to `false`
- **AND** the "NEW" badge reappears

### Requirement: Filter by review state
The system SHALL allow filtering the pipeline view by review state.

#### Scenario: Show only unreviewed
- **WHEN** a user selects "New only" from the pipeline filter
- **THEN** only cards with `reviewed = false` are shown in each stage

#### Scenario: Show all
- **WHEN** "All" is selected
- **THEN** all cards are shown regardless of review state

### Requirement: Default review state
The system SHALL default new applications to unreviewed.

#### Scenario: New application via public form
- **WHEN** a candidate applies through the public career page
- **THEN** their application has `reviewed = false`

#### Scenario: New application added manually
- **WHEN** a recruiter manually adds a candidate to a pipeline
- **THEN** the application has `reviewed = false`
