## 1. Add code quality dependencies

- [x] 1.1 Add `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` to `deps` in `mix.exs`
- [x] 1.2 Add `{:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}` to `deps` in `mix.exs`
- [x] 1.3 Run `mix deps.get` and verify both packages are installed

## 2. Configure credo

- [x] 2.1 Run `mix credo gen.config` to generate `.credo.exs`
- [x] 2.2 Review and tune `.credo.exs`: disable `Credo.Check.Readability.Specs`, adjust `CyclomaticComplexity` threshold to 12, keep all Warning checks at strict
- [x] 2.3 Run `mix credo --strict` against the existing codebase and fix any legitimate issues, add exclusions for false positives in `.credo.exs`

## 3. Configure sobelow

- [x] 3.1 Create `.sobelow-conf` with appropriate configuration for the project's Phoenix patterns
- [x] 3.2 Run `mix sobelow --config` against existing codebase and fix any vulnerabilities found, add exclusions for false positives

## 4. Update precommit alias

- [x] 4.1 Update the `precommit` alias in `mix.exs` to: `["format --check-formatted", "credo --strict", "sobelow --config", "compile --warnings-as-errors", "test"]`
- [x] 4.2 Verify `mix precommit` passes locally

## 5. Create CI workflow

- [x] 5.1 Create `.github/workflows/ci.yml` with `on: [push, pull_request]` targeting `main` and `workflow_dispatch`
- [x] 5.2 Add PostgreSQL service container (image `postgres:16`, health check with `pg_isready`)
- [x] 5.3 Add `erlef/setup-beam` step for Elixir ~> 1.15 and OTP ~> 26
- [x] 5.4 Add `actions/cache` steps for `deps/` and `_build/` directories with mix.lock-based cache keys
- [x] 5.5 Add steps: `mix deps.get --only test`, `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo --strict`, `mix sobelow --config`, `mix test`
- [x] 5.6 Set ENV vars for database connection to match the PostgreSQL service container

## 6. Verify CI pipeline

- [ ] 6.1 Push the branch to GitHub and confirm the CI workflow triggers
- [ ] 6.2 Verify all checks pass: formatting, credo, sobelow, compilation, tests
- [ ] 6.3 Create a test PR to verify PR trigger works correctly
- [ ] 6.4 Remove test PR
