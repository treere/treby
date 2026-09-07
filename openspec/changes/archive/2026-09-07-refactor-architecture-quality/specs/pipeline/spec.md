## ADDED Requirements

### Requirement: Pipeline context facade and modular decomposition
The system SHALL provide pipeline business logic through a delegating facade `Treby.Pipeline` that forwards to focused submodules `Pipeline.Stages`, `Pipeline.Applications`, and `Pipeline.Analytics`, preserving the existing public API and multi-tenant isolation. Analytics functions with and without tenant scoping SHALL share a single implementation via a private scoped-query helper.

#### Scenario: Facade preserves public API
- **WHEN** existing code calls `Treby.Pipeline.list_pipelines/1` or `Treby.Pipeline.move_application/3`
- **THEN** the call succeeds via `defdelegate` to the corresponding submodule without requiring call-site changes

#### Scenario: Analytics deduplication
- **WHEN** `pipeline_counts_per_stage/1` and `pipeline_counts_per_stage/2` are invoked with equivalent tenant scope
- **THEN** both return identical results because the tenant-scoped variant delegates to the single implementation filtered by tenant

#### Scenario: No behavioral regression after split
- **WHEN** the Kanban board loads, candidate cards are moved, or analytics are viewed after the refactor
- **THEN** all existing pipeline scenarios (board view, drag-and-drop, stage management, review state, bulk operations, real-time updates) continue to pass without modification
