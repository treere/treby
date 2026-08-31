## Why

Treby targets Italian and English users and already ships `TrebyWeb.Gettext` with `en`/`it` catalogs and a user-level locale preference. However, only a subset of the UI is actually wrapped with `gettext` — the dashboard and several LiveViews still contain hardcoded English strings (e.g., "Welcome", "My Actions", "Scorecards to fill", weekly-stats labels, empty states). There is no automated check that prevents new hardcoded or untranslated strings from shipping, so coverage regresses silently as features are added.

Users who select Italian still see a mixed-language interface, and contributors have no fast feedback when they forget a translation.

## What Changes

- Audit and wrap every user-facing string in the app (LiveViews, components, layouts, controllers/flash messages, email templates) with `gettext` / `ngettext` / `dgettext`, and extract catalogs via `mix gettext.extract --merge` so `priv/gettext/{en,it}/LC_MESSAGES/default.po` contains complete entries for both locales.
- Provide complete Italian `msgstr` translations for all newly extracted `msgid`s and fill any existing gaps where `msgstr ""` remains for `it`.
- Keep `en` as the reference locale (empty `msgstr` is acceptable for `en`, or copy `msgid` as `msgstr`) and enforce that `it` must have zero missing translations.
- Add an automated translation-coverage guard that runs locally and in CI to block merges when translations are missing or the POT catalog is stale:
  - a Mix task / script that compares `default.pot` against `priv/gettext/it/LC_MESSAGES/default.po` (and `errors.po`) and fails if any non-empty `msgid` has an empty `msgstr` or if the POT is out-of-date with source.
  - a custom Credo check (`Treby.Credo.Check.NoHardcodedUIStrings`) that flags hardcoded user-facing literals in `lib/treby_web/live/**`, `lib/treby_web/components/**` (HEEx templates, `~H` sigils, flash messages) that are not wrapped in `gettext`/`ngettext`, so contributors get immediate feedback in `mix credo --strict`.
  - optional `--check` mode for `mix gettext.extract` drift detection.
- Wire the guard (Mix task + Credo check) into `mix precommit` and `.github/workflows/ci.yml` so PRs fail fast on missing translations and on new hardcoded strings.
- Update docs (`site/`) and contributor guidance to describe the bilingual requirement and how to add new translatable strings.

## Capabilities

### New Capabilities
- `translation-coverage-guard`: automated detection and prevention of missing or stale translations for supported locales (`en`, `it`), with local and CI enforcement.

### Modified Capabilities
- `i18n`: expand from auth-only coverage to full-application bilingual (IT/EN) requirement; every user-facing string must be localizable and shipped with Italian translations.
- `dashboard`: require that all dashboard labels, headings, empty states, and flash messages are rendered via `gettext` and respect the user's locale (concrete example of the app-wide rule).

## Impact

- Code: `lib/treby_web/live/**` (notably `dashboard_live.ex` and all other LiveViews), `lib/treby_web/components/**`, `lib/treby_web/controllers/**`, `lib/mix/tasks/` or `scripts/` for the guard, `lib/treby/credo/check/no_hardcoded_ui_strings.ex` for the custom Credo check, `priv/gettext/**`, `mix.exs` aliases.
- Config/CI: `mix precommit` alias, `.github/workflows/ci.yml` (new `check-translations` + `credo --strict` step), `.credo.exs` (register custom check via `requires` + `checks.enabled`).
- No DB migrations.
- Dependencies: `gettext ~> 1.0` already present; no new hex deps required (guard is pure Elixir + PO parsing).
- Risk: large string extraction diff — mitigated by batching LiveView rewrites and reviewing PO files before merge; guard is fail-closed and must not block unrelated changes.
