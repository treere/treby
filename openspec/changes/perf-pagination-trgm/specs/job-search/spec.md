## ADDED Requirements

### Requirement: Indexed search
Job title/description/location search SHALL keep its current matching semantics and SHALL be served by a trigram (GIN) index on `jobs.title` so queries avoid sequential scans.

#### Scenario: Search uses trigram index
- **WHEN** a visitor searches jobs with any term
- **THEN** results match the previous semantics
- **AND** the query plan uses the trigram index instead of a sequential scan
