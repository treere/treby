## Why

LiveViews copy card, input, table, modal, and badge markup inline (~40 card copies, ~40 input copies, 12 raw tables, 4 raw modals, ~100 repeated status-to-variant mappings) instead of using `TrebyWeb.DesignSystem.*`. This causes visual drift, doubles theme fixes, and weakens the existing guardrail. Unifying call sites now restores the design system as single source of truth.

## What Changes

- Migrate card call sites (`jobs_live`, `candidates_live`, `settings_live/team`, others) to `<.card>` variants.
- Migrate raw inputs (`scorecard_form`, `pipeline_live`, `candidates_live/index`, `import_live`) to `<.input>` / DesignSystem field.
- Migrate raw `<table>` screens (`jobs_live/index`, `candidates_live/index`, `team`, `audit_log`, `webhooks`) to `<.table>`.
- Migrate raw modals (`scorecard_form`, `pipeline_live/index`, `candidates_live/show`, `layouts`) to `<.modal>` / `Pattern.ConfirmDialog`.
- Centralize status-to-variant mapping in `<.badge>` / `status_badge/1`; remove per-portal duplicate in `candidate_portal_live`.
- Extend `check_design_system` guardrail (mix task + pre-push + CI) to fail on copied card/input/table/modal/badge markup outside `design_system/*`.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `design-system`: tighten usage requirements to cover card, input, table, modal, and badge migration plus extended `check_design_system` scan rules.

## Impact

- Affected code: `lib/treby_web/live/**/*` (jobs, candidates, pipeline, settings, import, audit log, webhooks, candidate portal), `lib/treby_web/components/layouts.ex`, `lib/treby_web/components/design_system/*` (only if gaps found).
- Guardrail: `treby.check_design_system` mix task, `scripts/hooks/pre-push`, CI pre-push check.
- No DB migrations, no API changes, no new dependencies. Visual output must stay identical in light and dark themes; screenshots regenerated via `node scripts/screenshots.mjs`.
