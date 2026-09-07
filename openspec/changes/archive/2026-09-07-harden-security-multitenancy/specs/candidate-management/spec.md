## ADDED Requirements

### Requirement: Concurrent duplicate-email safety
The system SHALL guarantee that concurrent candidate creations with the same tenant and email produce a single active candidate. A partial unique index on active candidates SHALL back the application-level upsert.

#### Scenario: Concurrent creates return one candidate
- **WHEN** two requests create a candidate with the same tenant and email at the same time
- **THEN** exactly one active candidate exists afterwards
- **AND** both requests return `{:ok, candidate}` for that same record

#### Scenario: Merged candidates do not block reuse
- **WHEN** the only matching email belongs to an absorbed (merged) candidate
- **THEN** creation succeeds with a new candidate (tombstoned rows are excluded from uniqueness)
