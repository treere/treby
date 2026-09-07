## ADDED Requirements

### Requirement: Indexed search
Candidate name/email search SHALL remain case-insensitive contains matching and SHALL be served by trigram (GIN) indexes so leading-wildcard queries avoid sequential scans.

#### Scenario: Search uses trigram index
- **WHEN** a user searches candidates with any term (including `%` or partial words)
- **THEN** results match the previous `ilike` semantics
- **AND** the query plan uses the trigram index instead of a sequential scan
