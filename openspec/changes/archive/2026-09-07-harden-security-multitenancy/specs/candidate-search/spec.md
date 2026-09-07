## ADDED Requirements

### Requirement: Literal wildcard handling in search
The system SHALL treat `%`, `_`, and `\` typed in the candidate search input as literal characters, not as `LIKE` wildcards, while keeping case-insensitive contains semantics for all other input.

#### Scenario: Percent sign matches literally
- **WHEN** a user searches for `100%`
- **THEN** only candidates whose name or email contains the literal text `100%` are shown (not every candidate)

#### Scenario: Underscore matches literally
- **WHEN** a user searches for `a_b`
- **THEN** only candidates whose name or email contains the literal text `a_b` are shown (not `aab`, `axb`, etc.)
