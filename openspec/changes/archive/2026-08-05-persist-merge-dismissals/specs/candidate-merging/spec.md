## MODIFIED Requirements

### Requirement: Merge suggestions list
The system SHALL provide a merge center page listing detected duplicate groups with their confidence level, matching signal, and each candidate's data and application count.

#### Scenario: Merge center lists groups
- **WHEN** a user opens the merge center
- **THEN** duplicate groups are shown with a confidence badge and the shared signal
- **AND** each candidate is shown with anagrafica data and application count

#### Scenario: Dismiss a suggestion
- **WHEN** a user dismisses a merge suggestion
- **THEN** the group is no longer shown as a suggestion
- **AND** the dismissal is persisted for the tenant
- **AND** the group remains hidden on subsequent page loads
- **AND** no candidate data is changed

#### Scenario: Merge from suggestions
- **WHEN** a user confirms a suggested group
- **THEN** the merge is performed with the selected primary

#### Scenario: Duplicates badge excludes dismissed groups
- **WHEN** a tenant has a dismissed duplicate suggestion group
- **THEN** the candidates list "Duplicates" badge counts only the non-dismissed suggestion groups
