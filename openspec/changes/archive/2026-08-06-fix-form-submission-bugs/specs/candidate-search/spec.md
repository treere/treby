## MODIFIED Requirements

### Requirement: Search candidates
The system SHALL allow searching candidates by name or email.

#### Scenario: Text search
- **WHEN** a user types in the search input on the candidates page
- **THEN** candidates whose name or email contains the search term are shown (case-insensitive)

#### Scenario: Search on Enter
- **WHEN** a user types a term in the search input and presses Enter
- **THEN** the filtered results are shown in place
- **AND** the page does not perform a full reload
- **AND** the search term remains in the input

#### Scenario: Search from a shared URL
- **WHEN** a user loads the candidates page with a search query parameter (e.g. `?search=carol`)
- **THEN** the search input is pre-filled with the term
- **AND** only matching candidates are shown

#### Scenario: Empty search
- **WHEN** the search input is cleared
- **THEN** all candidates for the tenant are shown
