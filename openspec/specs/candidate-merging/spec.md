# Candidate Merging

## Purpose

Detect duplicate candidates, merge them into a single profile without losing data, and undo merges (split) reversibly.

## Requirements

### Requirement: Duplicate detection heuristics
The system SHALL detect likely duplicate candidates within a tenant using simple normalized signals: exact email, normalized phone combined with normalized name, and normalized name combined with matching email local-part.

#### Scenario: Exact email match auto-merges
- **WHEN** two non-tombstoned candidates in the same tenant share the same normalized email
- **THEN** the system merges them automatically into the older candidate
- **AND** an activity event records the merge

#### Scenario: Phone and name match is suggested
- **WHEN** two candidates have equal normalized phone and equal normalized name
- **THEN** the system presents them as a merge suggestion with high confidence
- **AND** the merge is not performed until confirmed

#### Scenario: Name and email local-part match is suggested
- **WHEN** two candidates have equal normalized name and equal email local-part with different domains
- **THEN** the system presents them as a merge suggestion with medium confidence

#### Scenario: Name-only match is not suggested
- **WHEN** two candidates share only a normalized name
- **THEN** the system does not suggest a merge between them

#### Scenario: Normalization rules
- **WHEN** comparing candidate data
- **THEN** email is lowercased and trimmed
- **AND** phone is reduced to digits with an optional leading country code removed
- **AND** name is lowercased, stripped of accents, and whitespace-collapsed

### Requirement: Merge candidates
The system SHALL merge two or more candidates into a single primary candidate. All applications, email threads, and candidate-level activity log entries of the absorbed candidates SHALL be reassigned to the primary. No candidate row, application, note, interview, or scorecard SHALL be deleted.

#### Scenario: Merge keeps all applications
- **WHEN** a user merges candidate A into candidate B
- **THEN** all of A's applications become applications of B
- **AND** notes, interviews, and scorecards attached to those applications remain intact
- **AND** A's email threads are reassigned to B

#### Scenario: Selectable primary anagrafica
- **WHEN** a user confirms a merge
- **THEN** they can choose which candidate's anagrafica becomes the master
- **AND** the first candidate in the merge group is selected by default

#### Scenario: Absorbed candidates become tombstones
- **WHEN** a candidate is merged into another
- **THEN** the absorbed candidate record is retained with a reference to the primary
- **AND** the absorbed candidate is excluded from candidate listings and searches
- **AND** its custom fields are left intact

#### Scenario: Duplicate applications to the same job are kept
- **WHEN** a merge results in two applications to the same job
- **THEN** both applications are kept
- **AND** each is flagged as a duplicate application for that job

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

### Requirement: Manual bulk merge
The system SHALL allow merging an arbitrary set of selected candidates from the candidates list.

#### Scenario: Bulk merge with primary picker
- **WHEN** a user selects multiple candidates and chooses "Merge into one"
- **THEN** a primary picker shows the selected candidates
- **AND** confirming the merge merges all of them into the chosen primary

### Requirement: Undo merge
The system SHALL allow undoing a merge. Undoing SHALL reassign each application, email thread, and activity log entry back to its original candidate and restore the absorbed candidate as an active profile. Undoing SHALL be possible only for the outermost merge in a chain.

#### Scenario: Undo restores all data
- **WHEN** a user undoes a merge
- **THEN** each reassigned application, email thread, and activity entry returns to its original candidate
- **AND** the absorbed candidate becomes active again and appears in listings
- **AND** no data is lost

#### Scenario: Chained merges require outermost undo first
- **WHEN** candidate A was merged into B and B was then merged into C
- **THEN** the merge of B into C can be undone
- **AND** the merge of A into B cannot be undone until B is restored

#### Scenario: Tombstoned candidates cannot be merged
- **WHEN** a user attempts to merge a candidate that is itself absorbed into another
- **THEN** the merge is refused
- **AND** the user is told to undo the prior merge first

### Requirement: Redirect absorbed profiles
The system SHALL redirect requests for an absorbed candidate's profile to the primary candidate's profile.

#### Scenario: Old profile URL redirects
- **WHEN** a user navigates to an absorbed candidate's profile URL
- **THEN** they are redirected to the primary candidate's profile
- **AND** a notice explains the profile was merged

### Requirement: Concurrent application visibility
The system SHALL indicate on pipeline board cards when a candidate has applications to other positions.

#### Scenario: Candidate active elsewhere
- **WHEN** a candidate on a job's pipeline board also has applications to other jobs
- **THEN** the card shows an indicator with the number of other positions
