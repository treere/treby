## ADDED Requirements

### Requirement: Literal wildcard handling in search
The system SHALL treat `%`, `_`, and `\` typed in job search inputs (global board and tenant career pages) as literal characters, not as `LIKE` wildcards, while keeping contains semantics for all other input.

#### Scenario: Percent sign matches literally
- **WHEN** a visitor searches for `100% remote`
- **THEN** only jobs containing the literal text `100% remote` are shown (not every job)
