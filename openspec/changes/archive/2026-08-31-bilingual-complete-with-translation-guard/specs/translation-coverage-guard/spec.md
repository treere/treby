## ADDED Requirements

### Requirement: Automated translation-coverage guard for supported locales
The system SHALL provide an automated guard that detects missing or stale translations for supported locales (`en`, `it`) and fails the build when coverage is incomplete, so that untranslated strings cannot be merged unnoticed.

#### Scenario: Guard fails on missing Italian translation
- **WHEN** `priv/gettext/it/LC_MESSAGES/default.po` (or `errors.po`) contains any non-header `msgid` with an empty `msgstr`
- **THEN** `mix treby.check_translations` exits with a non-zero status and prints the missing `msgid`(s) with file references from the POT

#### Scenario: Guard passes when Italian catalog is complete
- **WHEN** every `msgid` in `default.pot` has a non-empty `msgstr` in `it/LC_MESSAGES/default.po` and `errors.po` is complete
- **THEN** `mix treby.check_translations` exits with status 0

#### Scenario: Guard detects stale POT catalog
- **WHEN** source code contains a `gettext` string that is not present in `priv/gettext/default.pot` (developer forgot to run `mix gettext.extract --merge`)
- **THEN** the guard (or `mix gettext.extract` check mode) fails and instructs the developer to re-extract

#### Scenario: English catalog may keep empty msgstr
- **WHEN** `priv/gettext/en/LC_MESSAGES/default.po` contains empty `msgstr` entries
- **THEN** the guard does NOT treat them as failures (English falls back to `msgid`)

### Requirement: Guard enforced locally and in CI
The system SHALL enforce the translation-coverage guard both locally via `mix precommit` and in CI, so that missing translations block merges regardless of where checks run.

#### Scenario: Precommit blocks missing translations
- **WHEN** a developer runs `mix precommit` with a missing Italian translation present
- **THEN** the precommit run fails at the translation-check step

#### Scenario: CI blocks missing translations
- **WHEN** a pull request is opened with a missing Italian translation or stale POT
- **THEN** the CI workflow fails on the translation-check step and reports the missing keys

#### Scenario: Developer can run the guard in isolation
- **WHEN** a developer runs `mix treby.check_translations` directly
- **THEN** the task prints a summary (total keys, missing count, coverage %) and exits with the appropriate status without running the full test suite

### Requirement: Guard provides actionable diagnostics
The system SHALL provide actionable diagnostics when translations are missing, so that contributors can fix coverage quickly.

#### Scenario: Missing keys are listed with source references
- **WHEN** the guard fails due to missing translations
- **THEN** the output lists each missing `msgid`, its POT comment references (e.g., `lib/treby_web/live/dashboard_live.ex:163`), and the locale affected

#### Scenario: Summary statistics are printed
- **WHEN** the guard runs (pass or fail)
- **THEN** it prints total `msgid` count, translated count, missing count, and coverage percentage per checked locale

### Requirement: Credo check flags hardcoded UI strings outside Gettext
The system SHALL provide a custom Credo check that flags hardcoded user-facing strings in LiveViews, components, and controllers that are not wrapped in `gettext`/`ngettext`, so that missing translations are caught at lint time before extraction.

#### Scenario: Hardcoded string in dashboard triggers Credo violation
- **WHEN** `lib/treby_web/live/dashboard_live.ex` contains a raw literal like `"My Actions"` in a `~H` template outside a `gettext` call
- **THEN** `mix credo --strict` reports a violation from `Treby.Credo.Check.NoHardcodedUIStrings` with file, line, and the literal as trigger

#### Scenario: Gettext-wrapped string does not trigger violation
- **WHEN** a string is written as `gettext("My Actions")` or `gettext("Welcome, %{name}!", name: @user.name)`
- **THEN** the Credo check does not report a violation for that string

#### Scenario: Credo check ignores non-UI strings
- **WHEN** a file contains `class="..."`, `id="..."`, `phx-click="..."`, `hero-*` icon names, or technical identifiers
- **THEN** the Credo check does not report a violation

#### Scenario: Credo check runs in precommit and CI
- **WHEN** a developer runs `mix precommit` or CI runs `mix credo --strict` with a hardcoded UI string present
- **THEN** the run fails at the Credo step due to the custom check

#### Scenario: Escape hatch suppresses the check
- **WHEN** a line is annotated with `# credo:disable-for-next-line Treby.Credo.Check.NoHardcodedUIStrings` or uses an explicitly allowed non-UI literal
- **THEN** the Credo check does not report a violation for that line
