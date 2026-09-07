## MODIFIED Requirements

### Requirement: List candidates
The system SHALL display candidates for the current tenant in pages of 25 (configurable default) instead of all rows at once. Search and job/stage filters SHALL combine with pagination and reset to page 1 on change.

#### Scenario: Candidate listing page
- **WHEN** a user navigates to the candidates page
- **THEN** the first 25 candidates for their tenant are displayed with name, email, and application count
- **AND** a pager shows the result count and navigation controls

#### Scenario: Pager navigation
- **WHEN** a user clicks a page number or Next/Prev in the pager
- **THEN** that page of candidates is shown
- **AND** the URL updates with `?page=N` so the page is deep-linkable

#### Scenario: Filter resets pagination
- **WHEN** a user changes search text or job/stage filters
- **THEN** the listing returns to page 1
