## ADDED Requirements

### Requirement: Shared audit envelope helper
The system SHALL provide one thin audit envelope helper that builds only the repeated `%{tenant_id, actor_id, metadata %{before, after}}` envelope merged with caller payload and delegates to the existing `log_event`, preserving event names and payload keys at call sites with no behavior change.

#### Scenario: Envelope fields identical
- **WHEN** any migrated call site logs via the helper with `before`/`after`
- **THEN** the inserted event carries the same `tenant_id`, `actor_id`, and `metadata.before`/`metadata.after` as the pre-refactor literal

#### Scenario: Event and payload preserved
- **WHEN** any migrated call site in jobs, candidates, stages, scorecards, customization, or interviews logs a change
- **THEN** the event string and extra payload keys match the pre-refactor values and `log_event` remains the single insert path
