## Context

Treby already has Gettext wired (`TrebyWeb.Gettext`, `TrebyWeb.Hooks.SetLocale`, per-user `locale` field with `en`/`it` support, `priv/gettext/{en,it}/LC_MESSAGES/{default,errors}.po` and `default.pot`). Auth pages and several controllers were localized in prior work, but coverage is partial. Inspection of `dashboard_live.ex` and other LiveViews shows dozens of hardcoded English literals rendered directly in `~H` templates (e.g., "Dashboard", "Welcome", "My Actions", "Scorecards to fill", "Waiting on others", "Upcoming Interviews (7 days)", "No stale candidates", weekly-stats labels) and in flash/error messages (`"Scorecard submitted"`, `"Failed to submit scorecard"`). The dashboard is the most visible example of a systemic problem: without a guard, any new feature can ship untranslated strings and the `it` catalog drifts.

The locale is resolved from session (`SetLocale.on_mount(:set_locale, ...)`) and stored on user; `Gettext.put_locale/2` is called per LiveView mount. `en` is the source language (msgid = English). No CI check currently verifies that `default.pot` is up-to-date or that `it/default.po` has zero empty `msgstr` entries. Developers must remember to run `mix gettext.extract --merge` manually.

Stakeholders: end users (IT/EN), contributors, CI.

Constraints: keep `gettext ~> 1.0` with no new hex deps; `mix precommit` must stay fast; PO files are the source of truth; `en` may keep empty `msgstr` (Gettext falls back to `msgid`).

## Goals / Non-Goals

**Goals:**
- Every user-facing string (LiveViews, components, layouts, controllers, email subjects/bodies where exposed in UI, empty states, flash messages) is wrapped with `gettext`/`ngettext` and extracted to `default.pot`/`errors.pot`.
- `it/default.po` and `it/errors.po` have 100% coverage: zero `msgid` with empty `msgstr` (excluding header).
- A deterministic, fast guard runs locally and in CI that fails the build on (a) stale POT (source contains strings not in POT) and (b) missing Italian translations.
- The fix is demonstrated concretely on the dashboard (and similar high-traffic pages) so the pattern is repeatable.

**Non-Goals:**
- Supporting more than `en`/`it` in this change (infrastructure must allow adding locales later, but no third locale now).
- Machine-translation or external TMS integration.
- Runtime locale detection from `Accept-Language` / browser header (explicit user preference + session remains the mechanism).
- Pluralization overhaul beyond using `ngettext` where needed; no ICU message-format migration.
- Tenant-level custom translations.

## Decisions

### Decision 1: Full wrap + extract as the coverage mechanism

Wrap all literals with `gettext("…")` (and `gettext("…", var: val)` for interpolations, `ngettext` for counts). Then run `mix gettext.extract --merge` to regenerate `priv/gettext/default.pot` and merge into `priv/gettext/{en,it}/LC_MESSAGES/default.po`. English stays as `msgid`; `it` receives translated `msgstr`.

Alternatives considered:
- Custom JSON/i18n library: rejected — Gettext is already integrated, Phoenix-native, and tooling (`xgettext` extract, PO editors) is standard.
- Per-module domains (`dgettext` per feature): kept as optional optimization but not required; single `default` domain is sufficient and avoids fragmentation for now.

Why: minimal churn, leverages existing extractor, no new runtime.

### Decision 2: Guard = Mix task + custom Credo check, fail-closed

Introduce two complementary guard layers:

**2a. Mix task for PO completeness + POT staleness** — `mix treby.check_translations` (under `lib/mix/tasks/check_translations.ex`) that:
1. Parses `priv/gettext/default.pot` and `priv/gettext/it/LC_MESSAGES/default.po` (and `errors.po`) without external deps — simple PO parser scanning `msgid`/`msgstr` blocks.
2. Reports: (a) any `msgid != ""` where `msgstr` is empty/whitespace for `it`, (b) statistics (total, translated, missing, %), (c) optionally `en` drift is ignored (empty `msgstr` in `en` is OK).
3. Second mode `--check-pot`: runs `mix gettext.extract --check` logic by invoking `mix gettext.extract` to a temp dir and diffing, or by comparing current `default.pot` checksum against a fresh extraction; if templated strings changed without re-extraction, fail with instruction to run `mix gettext.extract --merge`.

Contract:
```elixir
@behaviour Mix.Task
# mix treby.check_translations [--locales it] [--pot priv/gettext/default.pot] [--check-pot]
# exit 0 = all translated and POT fresh; exit 1 = missing translations or stale POT, prints file:line hints from POT references.
```

**2b. Custom Credo check for hardcoded strings** — `Treby.Credo.Check.NoHardcodedUIStrings` (under `lib/treby/credo/check/no_hardcoded_ui_strings.ex`, generated via `mix credo.gen.check`):

- Implements `Credo.Check` behaviour; `use Credo.Check, base_priority: :high, category: :warning`.
- Scans `lib/treby_web/live/**`, `lib/treby_web/components/**`, `lib/treby_web/controllers/**` for user-facing literals outside `gettext`:
  - In `~H` sigils / `.heex` templates: raw text nodes and attribute values that match `/[A-Z][a-z]{2,}/` and are not inside `gettext(` / `ngettext(` / `dgettext(` calls.
  - In Elixir code: string literals assigned to `:flash`, `put_flash`, `title`, `label`, `description` that are not wrapped in `gettext`.
- Heuristics to reduce false positives: ignores `class`, `id`, `phx-*`, `hero-*`, technical keys, single-word placeholders, and strings marked with `# credo:disable-for-next-line Treby.Credo.Check.NoHardcodedUIStrings` or `gettext_noop`.
- Reports `Credo.Issue` with `line_no`, `column`, `message: "Hardcoded UI string outside gettext — wrap with gettext(\"…\")"`, `trigger: <literal>`.
- Registered in `.credo.exs` via `requires: ["lib/treby/credo/check/no_hardcoded_ui_strings.ex"]` and `checks: %{enabled: [{Treby.Credo.Check.NoHardcodedUIStrings, []}]}` so `mix credo --strict` fails on violations.

Alternatives: Node script parsing PO, GitHub Action using `msgfmt --check`, or `rg`-only lint. Decision: Mix task handles PO completeness (authoritative), Credo handles *source-level* prevention (fastest feedback in editor/CI). Both run in `mix precommit` without extra tooling and can print `::error` annotations for CI.

Error handling: fail-closed — any missing `it` translation, stale POT, or Credo violation fails the respective check; missing `it` file also fails. On parser error, fail with diagnostic.

### Decision 3: Enforcement points — `mix precommit` + CI job step

- Extend `mix precommit` alias to include `mix treby.check_translations` and `mix credo --strict` (which now includes the custom check) — order: `format --check-formatted`, `credo --strict`, `treby.check_translations`, then `compile/test`.
- Add explicit steps in `.github/workflows/ci.yml` (or reuse `precommit`): (1) `mix gettext.extract --merge` dry-check, (2) `mix treby.check_translations`, (3) `mix credo --strict` (fails on hardcoded strings). Use dry-run extraction + PO diff so CI catches forgotten extractions even if developer skipped local run.
- Pre-commit is advisory; CI is blocking. Credo check also surfaces inline in editors via `mix credo --strict`.

Alternative: only CI — rejected because fast local feedback is needed (especially for dashboard-style misses); Credo gives instant feedback without waiting for full PO round-trip.

### Decision 4: Handling `en` catalog

`en` keeps empty `msgstr` by convention (Gettext fallback). Guard skips `en` for empty checks but still verifies POT freshness. This avoids churn of copying `msgid` into `msgstr` for `en`.

### Decision 5: Dashboard as reference implementation

Fix `lib/treby_web/live/dashboard_live.ex` first (title, welcome with interpolation, weekly-stats labels, My Actions headings, empty states, activity labels, flash messages, onboarding checklist labels) to establish the gettext pattern. Then sweep remaining LiveViews batch-wise (`candidates_live`, `jobs_live`, `settings_live/*`, `interviews_live`, `pipeline_live`, `components/layouts.ex` where not already covered) using the same pattern: `gettext("My Actions")`, `gettext("Welcome, %{name}!", name: @current_user.name)` etc. Keep `gettext` calls static (no dynamic `msgid` construction) so extractor can find them.

Multi-tenant isolation: not applicable — translations are global, not per-tenant. Tenant scoping unchanged.

Caching: Gettext translations are compiled into modules; no runtime cache invalidation beyond recompilation. Guard has no cache.

Authorization: locale preference is per-user; no role check needed beyond existing `SetLocale` hook. Every authenticated LiveView already calls `set_locale_from_session/2`; unauthenticated pages use session locale or default `en`.

## Risks / Trade-offs

- [Large PO diff touches many files] → Mitigation: split extraction by area (dashboard first, then candidates/jobs/settings), review `it` translations in a single PR, use `mix gettext.extract --merge` to keep line references stable; provide glossary for recurring terms (e.g., "Pipeline", "Stage", "Scorecard").
- [Translator drift / inconsistent Italian terms] → Mitigation: seed `it/default.po` from prior translations, keep style guide in contributor docs; guard only checks completeness, not quality — quality is reviewed in PR.
- [Guard false positives from intentionally untranslated strings (brand names, placeholders)] → Mitigation: allow `gettext` comment hints or explicit `dgettext("untranslated", ...)` escape hatch documented in task; otherwise require translation.
- [POT staleness check is slow or flaky] → Mitigation: keep check as lightweight file mtime + content hash; CI runs fresh `mix gettext.extract` to temp dir and diffs — no network.
- [Interpolated strings break extraction if built dynamically] → Mitigation: enforce static `msgid` + keyword interpolation (`gettext("Welcome, %{name}!", name: ...)`) and enforce via custom Credo check + code-review checklist.
- [Custom Credo check noisy on false positives] → Mitigation: narrow file globs to `lib/treby_web/{live,components,controllers}` only, allowlist `class`/`id`/`phx-*`/`hero-*`, provide `credo:disable` escape hatch, start with `exit_status: 0` in warning mode if needed then promote to blocking once dashboard sweep is clean.

## Migration Plan

1. Land Mix task `treby.check_translations` and wire to `mix precommit` + CI (guard initially in warning mode if needed, then fail-closed).
2. Run `mix gettext.extract --merge` after wrapping strings; commit updated `priv/gettext/default.pot` and merged `priv/gettext/{en,it}/LC_MESSAGES/*.po`.
3. Fill `it` `msgstr` for all newly extracted keys (copy prior translations where `msgid` unchanged).
4. Deploy — no migration, no feature flag; recompilation picks up new PO. Rollback = revert commit (translations are additive).
5. Follow-up sweep for any residual hardcoded strings found by a one-off `rg '"[A-Z][a-z ]' lib/treby_web --glob '*.ex'` audit filtered against `gettext` calls.

## Open Questions

- Should the custom Credo check also cover `.heex` files on disk outside `lib/treby_web`? Decision: v1 covers `lib/treby_web/**` only; standalone `.heex` files are covered via their compiled `~H` sigils, so no separate parser needed initially.
- Should `en/default.po` be kept with copied `msgstr` for tooling compatibility? Decision: keep empty (Phoenix convention) and document; guard skips `en` empty check.
- Do email templates need tenant-branded strings excluded from translation? Out of scope — only UI subjects/flash that are user-facing are translated in this change.
