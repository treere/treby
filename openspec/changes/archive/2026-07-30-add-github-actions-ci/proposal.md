## Why

Treby has no CI pipeline for its Elixir application. Code quality checks (formatting, linting, security analysis) and tests only run on demand via `mix precommit`. Without automated CI, issues slip through — unformatted code, compiler warnings, failing tests, and security vulnerabilities go undetected until someone happens to run the right command. A GitHub Actions CI pipeline ensures every push is automatically verified, enforcing code quality standards and catching regressions early.

## What Changes

- **Add a GitHub Actions CI workflow** (`.github/workflows/ci.yml`) that runs on every push and pull request to `main`: checks formatting, runs static analysis, scans for security vulnerabilities, compiles with warnings-as-errors, and executes the full test suite against PostgreSQL
- **Add and configure `credo`** for static code analysis with a `.credo.exs` config tuned to the project's existing style
- **Add and configure `sobelow`** for security scanning
- **Update the `precommit` alias** in `mix.exs` to include `format --check-formatted`, `credo`, `sobelow`, and `test` — matching CI checks
- **Add a PostgreSQL service container** to the CI workflow for running tests that require a database

## Capabilities

### New Capabilities
- `ci-pipeline`: Automated CI pipeline on GitHub Actions that runs formatting checks, static analysis, security scanning, compilation, and tests on every push/PR to `main`

### Modified Capabilities
<!-- No existing specs change behavior — this is net-new infrastructure. -->

## Impact

- **New file**: `.github/workflows/ci.yml` — GitHub Actions CI workflow
- **New file**: `.credo.exs` — Credo configuration
- **New dependency**: `credo` — static code analysis (dev/test only)
- **New dependency**: `sobelow` — security scanning (dev/test only)
- **Modified**: `mix.exs` — `precommit` alias updated to run all checks
- **No runtime impact**: all changes are dev/test-only infrastructure
