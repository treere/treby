## ADDED Requirements

### Requirement: Time-ordered candidate ids
Candidate primary keys SHALL be time-ordered UUIDv7, so that for rows created after the switch, descending id order reflects reverse insertion order.

#### Scenario: Same-timestamp candidates order by id
- **WHEN** two candidates share the same `inserted_at` timestamp
- **THEN** the candidate list orders them by descending id (newest first)

#### Scenario: Existing ids remain valid
- **WHEN** records created before the switch (random UUIDv4) are listed
- **THEN** they appear and remain addressable with no migration or data change
