## Context

Treby has no CI for its Elixir application. The only automation is a GitHub Actions workflow that deploys the Vitepress docs site. The `precommit` alias (`compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `test`) runs all local checks but is not enforced on push or PR. The project has no credo or sobelow — static analysis and security scanning are entirely absent.

The CI needs PostgreSQL for the test suite (shared DB setup via `mix test` alias), which means a service container in CI. Elixir CI is well-established with `erlef/setup-beam` for runtime setup and caching strategies for deps and compiled artifacts.

## Goals / Non-Goals

**Goals:**
- Run `mix format --check-formatted` to enforce consistent formatting
- Run `mix credo` for static code analysis
- Run `mix sobelow` for security vulnerability scanning
- Run `mix compile --warnings-as-errors` to ensure zero-warning compilation
- Run `mix test` with a PostgreSQL service container
- Cache Mix dependencies (`deps/`) and compiled output (`_build/`) between runs for fast CI
- Update the local `precommit` alias to match the full CI check suite
- Fail on any check failure — no soft warnings

**Non-Goals:**
- No dialyzer (slow, heavy, adds ~5-10min per run; can be added separately later)
- No coverage reporting (no excoveralls dep; can be added later)
- No deployment or release automation
- No matrix testing (single Elixir/OTP version matching the project's `mix.exs` minimum)
- No linting of the `site/` directory (that's JavaScript, separate concern)

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **CI platform** | GitHub Actions | Already used for deploy-pages. Standard for GitHub-hosted projects. Zero additional setup. |
| **Elixir setup** | `erlef/setup-beam` | Official BEAM community action. Handles Elixir + OTP version installation with caching. Mature and widely adopted. |
| **PostgreSQL in CI** | `services.postgres` | Avoids extra dependencies. GitHub-hosted Ubuntu runners have PostgreSQL available, but a service container gives version control matching `docker-compose.yml`. Use the same PostgreSQL 18 image. |
| **Cache strategy** | `actions/cache` with keys for `deps` and `_build` | Separate cache keys for dependencies and compiled output. Invalidate `_build` when `mix.lock` changes. This cuts CI time from ~5-8min to ~2-3min. |
| **Linter** | credo | Industry-standard static analysis for Elixir. Flexible configuration via `.credo.exs`. Tune checks to avoid noise on existing code. |
| **Security scanner** | sobelow | Purpose-built for Phoenix security analysis. Checks for SQL injection, XSS, hardcoded secrets, etc. Runs quickly (seconds). |
| **Workflow structure** | Single job with sequential steps | Simpler than multi-job pipeline. All checks must pass for a green CI. Sequential steps give clear failure output. Can split into parallel jobs later if CI time becomes an issue. |
| **precommit alias** | Mirror CI checks locally | Ensures developers can reproduce CI results before pushing. `precommit` runs `format --check-formatted`, `credo`, `sobelow`, `compile --warnings-as-errors`, and `test`. |
| **Failure behavior** | `continue-on-error: false` on all steps | Every check gates the pipeline. A credo warning is treated the same as a test failure — the CI fails and the PR is blocked. This enforces standards consistently. |

## CI Workflow Design

```
.github/workflows/ci.yml

on: [push, pull_request] → main

jobs:
  elixir_ci:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: treby_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      1. Checkout
      2. Setup Elixir (erlef/setup-beam)
         - elixir: ~> 1.15
         - otp: ~> 26
      3. Cache Mix dependencies (deps/)
      4. Cache compiled build (_build/)
      5. Install deps (mix deps.get --only test)
      6. Compile (mix compile --warnings-as-errors)
      7. Check formatting (mix format --check-formatted)
      8. Run credo (mix credo --strict)
      9. Run sobelow (mix sobelow --config)
      10. Run tests (mix test)
```

The `mix test` alias in `mix.exs` already handles DB creation and migration, and the PostgreSQL service container provides the database server for it.

## Credo Configuration

Use a `.credo.exs` file that enables most checks but disables a few noisy ones:
- `Credo.Check.Readability.Specs` — not relevant (this isn't an OSS library)
- `Credo.Check.Refactor.CyclomaticComplexity` — increase threshold slightly for Phoenix LiveViews (which tend to be longer)
- Keep `Credo.Check.Warning` category at full strictness

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| credo produces warnings on existing code, blocking CI on first run | Run `mix credo` locally first, fix all issues or configure exceptions in `.credo.exs`. New code must pass from day one. |
| sobelow flags Phoenix patterns as false positives | sobelow has a config mechanism to skip specific checks. Handle false positives case by case in `.sobelow-conf`. |
| CI time too long (~5-8min) | Caching keeps most runs under 3min. If it becomes an issue, split into parallel jobs (lint, test). |
| PostgreSQL version mismatch between CI and dev | Use `postgres:16` in CI (common default). The app uses Ecto with standard SQL, so minor version differences are harmless. |
| `deps.unlock --unused` fails in CI (not a dev env) | Remove `deps.unlock --unused` from CI precommit — it's a development hygiene check, not relevant in CI. Keep it in local `precommit` only. |
| Developer resistance to strict CI | The precommit alias already runs most checks. Adding credo and sobelow brings marginal additional friction for significant quality gains. |
