## ADDED Requirements

### Requirement: Bulk compare
The system SHALL allow comparing 2-3 selected candidates side-by-side from the bulk action bar.

#### Scenario: Compare action in action bar
- **WHEN** a user selects 2-3 candidates in the candidates list and chooses "Compare" from the action bar dropdown
- **THEN** a "Compare" confirm button is shown

#### Scenario: Compare navigates to comparison view
- **WHEN** a user clicks "Compare"
- **THEN** the system navigates to the comparison view with the selected candidate ids in the URL
