## ADDED Requirements

### Requirement: Candidates context facade and query centralization
The system SHALL provide candidate business logic through a delegating facade `Treby.Candidates` that forwards listing/search/filter to `Candidates.Queries` and merge/undo to `Candidates.Merge`, with no inline `import Ecto.Query` inside functions and with `stringify_keys` centralized in `Treby.Helpers.Map`. Tenant isolation and search/filter behavior SHALL remain identical.

#### Scenario: Facade preserves public API
- **WHEN** existing code calls `Treby.Candidates.list_candidates/2` or `Treby.Candidates.merge_candidates/3`
- **THEN** the call succeeds via `defdelegate` to `Candidates.Queries` or `Candidates.Merge` without requiring call-site changes

#### Scenario: Query helpers centralized
- **WHEN** `list_candidates/2` is invoked with `search`, `job_id`, or `stage_id` filters
- **THEN** results match pre-refactor behavior because `apply_search`, `apply_job_filter`, and `apply_stage_filter` are defined once in `Candidates.Queries` and reused

#### Scenario: Shared helper deduplication
- **WHEN** candidate creation or application creation stringifies attribute keys
- **THEN** both paths use `Treby.Helpers.Map.stringify_keys/1` and no duplicate `defp stringify_keys` remains in `candidates.ex` or `pipeline.ex`
