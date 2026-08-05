## MODIFIED Requirements

### Requirement: Select candidates for comparison
The system SHALL allow selecting 2-3 candidates for a side-by-side comparison from the candidates list.

#### Scenario: Select candidates from the list
- **WHEN** a user views the candidates list
- **THEN** each row has a checkbox
- **AND** the bulk action bar appears when candidates are selected
- **AND** the bulk action bar includes a "Compare" action

#### Scenario: Compare navigates with selected ids
- **WHEN** a user selects 2-3 candidates and clicks "Compare"
- **THEN** the system navigates to the comparison view with the candidate ids in the URL

#### Scenario: Selection limit
- **WHEN** a user tries to select more than 3 candidates for comparison
- **THEN** the system prevents the comparison and shows "Maximum 3 candidates for comparison"

#### Scenario: Minimum selection
- **WHEN** a user clicks "Compare" with fewer than 2 candidates selected
- **THEN** the system shows "Select at least 2 candidates to compare"

#### Scenario: Compare view without candidate ids
- **WHEN** a user opens the comparison view without candidate ids in the URL
- **THEN** the system shows an empty state prompting the user to select candidates from the list

### Requirement: Comparison persistence
The system SHALL preserve the selected comparison candidates when navigating to the comparison view.

#### Scenario: Return via URL
- **WHEN** a user navigates away from the comparison view and returns to the same URL
- **THEN** the comparison view shows the same candidates encoded in the URL

#### Scenario: Back to candidates
- **WHEN** a user clicks "← Back to candidates"
- **THEN** the user returns to the candidates list
