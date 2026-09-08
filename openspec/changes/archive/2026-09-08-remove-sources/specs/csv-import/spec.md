## MODIFIED Requirements

### Requirement: Import candidates
The system SHALL import candidates from the mapped CSV.

#### Scenario: Successful import
- **WHEN** the user confirms the import
- **THEN** all valid rows are imported as candidates and applications
- **AND** a summary is shown: "X imported, Y duplicates skipped, Z errors"

#### Scenario: Import with job assignment
- **WHEN** the user selects a target job and pipeline stage during import
- **THEN** each imported candidate gets an application for that job in the specified stage

#### Scenario: Import without job assignment
- **WHEN** no target job is selected
- **THEN** candidates are created without applications

#### Scenario: Deduplication by email
- **WHEN** a CSV row has an email that matches an existing candidate in the tenant
- **THEN** the candidate is NOT created again
- **AND** the row is counted as a duplicate

#### Scenario: Import in single transaction
- **WHEN** the import encounters an error mid-way
- **THEN** no partial data is committed — the entire import is rolled back
- **AND** an error message is shown
