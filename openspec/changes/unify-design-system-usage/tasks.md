## 1. Badge mapping + portal duplicate

- [x] 1.1 Add `status_variant/1` + `status_badge` to DesignSystem, enumerate canonical status vocabulary across jobs/candidates/pipeline — verify with `mix test test/treby_web/components/design_system_test.exs`
- [x] 1.2 Migrate all inline status-to-variant `case` maps to `<.status_badge>` — verify with `grep -R "case.*status.*emerald\|badge.*variant.*case" lib/treby_web --include="*.ex" --include="*.heex" | grep -v design_system` clean
- [x] 1.3 Delete `candidate_portal_live` badge duplicate, render via `<.status_badge>` with zero visual change — verify with `mix test test/treby_web/live/candidate_portal_live_test.exs` + screenshots diff light/dark

## 2. Tables

- [x] 2.1 Migrate `jobs_live/index` raw `<table>` to core `<.table>` preserving id/rows/row_click/streams — verify with `mix test test/treby_web/live/jobs_live_test.exs`
- [x] 2.2 Migrate `candidates_live/index` raw `<table>` to core `<.table>` preserving streams and row actions — verify with `mix test test/treby_web/live/candidates_live_test.exs`
- [x] 2.3 Migrate `settings_live/team`, `audit_log`, `webhooks` tables to core `<.table>` — verify with `mix test test/treby_web/live/settings_live_test.exs` + `grep -R "<table[ >]" lib/treby_web --include="*.ex" --include="*.heex"` clean

## 3. Cards

- [x] 3.1 Migrate `jobs_live` + `candidates_live` card copies to `<.card variant>` with header/footer slots — verify with `mix test test/treby_web/live/jobs_live_test.exs test/treby_web/live/candidates_live_test.exs`
- [x] 3.2 Migrate `settings_live/*` + portal/careers leftover cards to `<.card>` (default/bordered/elevated/flat per design D1) — verify with `grep -R "bg-white dark:bg-zinc-800 rounded-xl border" lib/treby_web --include="*.ex" --include="*.heex" | grep -v design_system` clean

## 4. Inputs

- [x] 4.1 Migrate `scorecard_form` + `import_live` forms to `to_form/2`-driven `<.input>` — verify with `mix test test/treby_web/live/scorecard_test.exs test/treby_web/live/import_live_test.exs`
- [x] 4.2 Migrate `pipeline_live` search + `candidates_live/index` filters to `input_classes/select_classes/textarea_classes` + `Pattern.filter_bar/form_section` — verify with `mix test test/treby_web/live/pipeline_live_test.exs` + per-file check for bare `class=` without DS tokens clean

## 5. Modals

- [x] 5.1 Migrate `scorecard_form` + `pipeline_live/index` dialogs to `<.modal>` / `Pattern.confirm_dialog` keeping event names verbatim — verify with `mix test test/treby_web/live/pipeline_live_test.exs` + manual open/close in both themes
- [x] 5.2 Migrate `candidates_live/show` + `layouts` dialogs to `<.modal>` / confirm_dialog (danger vs primary per D4) — verify with `mix test test/treby_web/live/candidates_live_test.exs` + `grep -R "fixed inset-0 z-50" lib/treby_web --include="*.ex" --include="*.heex" | grep -v design_system` clean

## 6. Guardrail + verification + docs

- [x] 6.1 Extend `treby.check_design_system` with copied-card-shell, raw-table, raw-modal-shell, raw-input, copied-badge patterns — verify with `mix treby.check_design_system` green
- [ ] 6.2 Regenerate screenshots via `node scripts/screenshots.mjs`, diff light + `25-dark-mode.png`, then run `node scripts/screenshots.mjs --axe` with zero serious/critical violations
- [ ] 6.3 Update `openspec/specs/design-system/spec.md` with Purpose/Requirements and Scenario WHEN/THEN for card/input/table/modal/badge + guardrail
- [ ] 6.4 Sync user manual: confirm no user-visible change in `site/features/` else update page + sidebar in `site/.vitepress/config.ts` + `site/features/index.md`
- [ ] 6.5 Run `mix precommit` and `openspec validate --strict` and fix all issues
