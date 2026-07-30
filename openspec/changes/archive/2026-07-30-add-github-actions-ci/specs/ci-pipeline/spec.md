## ADDED Requirements

### Requirement: CI runs on push and pull request to main

The system SHALL trigger the CI pipeline automatically on every push and pull request targeting the `main` branch. Manual trigger via `workflow_dispatch` SHALL also be supported.

#### Scenario: Push to main triggers CI

- **WHEN** a commit is pushed to the `main` branch
- **THEN** the CI pipeline SHALL start automatically

#### Scenario: Pull request triggers CI

- **WHEN** a pull request is opened or updated targeting the `main` branch
- **THEN** the CI pipeline SHALL start automatically

#### Scenario: Manual trigger

- **WHEN** a maintainer triggers the workflow via GitHub UI (`workflow_dispatch`)
- **THEN** the CI pipeline SHALL start on the selected branch

### Requirement: CI checks formatting

The system SHALL verify that all Elixir source files match `mix format --check-formatted`. Any unformatted file SHALL cause the pipeline to fail.

#### Scenario: All files formatted

- **WHEN** `mix format --check-formatted` exits with status 0
- **THEN** the pipeline continues to the next check

#### Scenario: Unformatted file detected

- **WHEN** `mix format --check-formatted` exits with non-zero status
- **THEN** the pipeline SHALL fail immediately

### Requirement: CI runs static analysis with credo

The system SHALL run `mix credo --strict` and fail on any credo warning. The `.credo.exs` configuration SHALL be checked into the repository.

#### Scenario: credo passes

- **WHEN** `mix credo --strict` exits with status 0
- **THEN** the pipeline continues to the next check

#### Scenario: credo finds issues

- **WHEN** `mix credo --strict` exits with non-zero status
- **THEN** the pipeline SHALL fail with credo's output displayed

### Requirement: CI scans for security vulnerabilities with sobelow

The system SHALL run `mix sobelow --config` and fail if any security issues are found at the configured severity threshold.

#### Scenario: sobelow passes

- **WHEN** `mix sobelow --config` exits with status 0
- **THEN** the pipeline continues to the next check

#### Scenario: sobelow finds issues

- **WHEN** `mix sobelow --config` exits with non-zero status
- **THEN** the pipeline SHALL fail with sobelow's output displayed

### Requirement: CI compiles with warnings-as-errors

The system SHALL compile the project with warnings treated as errors. Any compiler warning SHALL cause the pipeline to fail.

#### Scenario: Clean compilation

- **WHEN** `mix compile --warnings-as-errors` exits with status 0
- **THEN** the pipeline continues to the next check

#### Scenario: Compiler warning

- **WHEN** `mix compile --warnings-as-errors` exits with non-zero status
- **THEN** the pipeline SHALL fail with the compiler output displayed

### Requirement: CI runs the test suite

The system SHALL provide a PostgreSQL service container and run the full test suite via `mix test`. All tests MUST pass for the pipeline to succeed.

#### Scenario: All tests pass

- **WHEN** `mix test` exits with status 0
- **THEN** the pipeline SHALL report success

#### Scenario: Test failure

- **WHEN** `mix test` exits with non-zero status
- **THEN** the pipeline SHALL fail with test output displayed

#### Scenario: PostgreSQL connection

- **WHEN** the `mix test` alias runs `ecto.create --quiet` and `ecto.migrate --quiet`
- **THEN** they SHALL connect to the PostgreSQL service container successfully

### Requirement: Dependencies and build artifacts are cached

The system SHALL cache Mix dependencies (`deps/`) and compiled build output (`_build/`) between CI runs to reduce pipeline duration. Cache keys SHALL be invalidated when `mix.lock` changes.

#### Scenario: Cache hit on dependencies

- **WHEN** `mix.lock` has not changed since the last CI run
- **THEN** `mix deps.get` SHALL restore dependencies from cache

#### Scenario: Cache miss

- **WHEN** `mix.lock` has changed since the last CI run
- **THEN** dependencies SHALL be fetched fresh and the cache SHALL be updated

### Requirement: Local precommit alias matches CI checks

The system SHALL provide a `mix precommit` alias that runs the same checks as CI locally, including `format --check-formatted`, `credo`, `sobelow`, `compile --warnings-as-errors`, and `test`.

#### Scenario: Running precommit locally

- **WHEN** a developer runs `mix precommit`
- **THEN** it SHALL execute formatting check, credo, sobelow, compilation with warnings-as-errors, and tests in sequence

#### Scenario: Precommit passes

- **WHEN** all precommit steps exit with status 0
- **THEN** the developer sees a success message

#### Scenario: Precommit fails

- **WHEN** any precommit step exits with non-zero status
- **THEN** the developer sees the failing step's output and the pipeline stops
