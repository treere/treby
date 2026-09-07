## ADDED Requirements

### Requirement: Single-write duplicate-flag recompute
Recomputing duplicate flags for a candidate SHALL issue a single write query that sets `is_duplicate` true for later same-job applications and false for all others.

#### Scenario: Recompute flags
- **WHEN** duplicate flags are recomputed for a candidate with several applications
- **THEN** the earliest application per job is flagged false and later same-job applications true
- **AND** exactly one write query is issued

### Requirement: Preloaded candidate on application creation
Application creation SHALL accept an optional preloaded candidate record to skip the per-row fetch; when absent, the existing lazy fetch behavior SHALL apply.

#### Scenario: Caller passes candidate
- **WHEN** creating an application with the candidate record provided
- **THEN** no extra candidate query is issued

#### Scenario: Caller omits candidate
- **WHEN** creating an application without the candidate record
- **THEN** the candidate is fetched by id as before
