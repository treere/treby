# Candidate Comparison

## Purpose

Allow hiring managers to compare 2-3 final candidates side-by-side to make structured, informed hiring decisions.

## Requirements

### Requirement: Select candidates for comparison
The system SHALL allow selecting 2-3 candidates for a side-by-side comparison.

#### Scenario: Compare button on candidate cards
- **WHEN** a user views the candidates list or pipeline board
- **THEN** each candidate card has a "Compare" checkbox or button

#### Scenario: Selection limit
- **WHEN** a user tries to select more than 3 candidates
- **THEN** the system prevents the selection and shows "Maximum 3 candidates for comparison"

#### Scenario: Minimum selection
- **WHEN** a user clicks "Compare" with fewer than 2 candidates selected
- **THEN** the system shows "Select at least 2 candidates to compare"

### Requirement: Side-by-side comparison view
The system SHALL display selected candidates in a side-by-side comparison grid.

#### Scenario: Comparison grid layout
- **WHEN** a user initiates a comparison
- **THEN** a page or panel shows each candidate as a column with the following sections:
  - Contact info (name, email, phone, LinkedIn)
  - Custom fields
  - All applications (job title, current stage)
  - All notes with ratings
  - All scorecards (scores, recommendation)
  - Interview history (dates, status)

#### Scenario: Empty data handling
- **WHEN** a candidate has no data for a section (e.g., no scorecards)
- **THEN** that section shows "No data" or is hidden

#### Scenario: Resume link
- **WHEN** a candidate has an uploaded resume
- **THEN** a "View Resume" link is shown in their column

### Requirement: Highlight differences
The system SHALL visually highlight key differences between candidates.

#### Scenario: Score comparison
- **WHEN** candidates have scorecard scores for the same criteria
- **THEN** the highest score per criterion is visually highlighted (e.g., bold or colored)

#### Scenario: Stage comparison
- **WHEN** candidates are in different pipeline stages
- **THEN** each candidate's current stage is shown with its color

### Requirement: Comparison persistence
The system SHALL persist the comparison selection during the session.

#### Scenario: Navigate away and return
- **WHEN** a user navigates away from the comparison view
- **THEN** the selected candidates are remembered
- **AND** returning to the comparison view shows the same candidates

#### Scenario: Clear comparison
- **WHEN** a user clicks "Clear comparison"
- **THEN** all candidates are deselected and the comparison view closes
