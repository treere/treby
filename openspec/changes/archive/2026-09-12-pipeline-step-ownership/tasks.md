## 1. LiveView UI — Job Detail Pipeline Overview

- [x] 1.1 Update read-only pipeline overview in `TrebyWeb.JobsLive.Show` to always render an explicit owner line per stage: when any of examiners/reviewers/advancers is non-empty show names with full role labels (`Examiner:`, `Reviewer:`, `Advancer:`); when all empty show `Responsible: Everyone` via `gettext("Everyone")`. Verify in light + dark.
- [x] 1.2 Add roles legend (one muted line) above the stage list in the overview (e.g., `Examiner — runs interviews · Reviewer — reviews · Advancer — moves candidates`) using `gettext` strings.
- [x] 1.3 Add short "how it works" explainer in the Pipeline section (ordered stages, interview-stage advancer gating, job-dedicated copy note). Keep 2–3 sentences; use `<details>` if noisy. All strings via `gettext`.
- [x] 1.4 Align manage-mode stage list (`stages_with_counts` branch) to same ownership display (names with full labels or `Everyone` fallback) so overview and editor never contradict. Remove or supplement compact `2E` counts.

## 2. Tests

- [x] 2.1 Add/extend LiveView tests for job detail pipeline overview: stage with no assignments shows `Everyone`; stage with assignments shows full role labels + names; legend is present; explainer is present. Run `mix test test/treby_web/live/jobs_live_test.exs` (or relevant path).
- [x] 2.2 Add test for manage-mode editor ownership line consistency (same fallback/labels). Verify non-admin cannot edit is unchanged.

## 3. Specs & Docs

- [x] 3.1 Sync main specs: update `openspec/specs/pipeline/spec.md` and `openspec/specs/job-pipeline-editor/spec.md` to reflect explicit owner line, "Everyone" fallback, legend, and explainer (requirements + scenarios already captured in delta; copy relevant parts to main specs on archive/sync).
- [x] 3.2 Update user manual `site/features/pipeline.md` (Pipeline Overview, Per-Stage Permissions) to document the owner line, `Everyone` fallback, and the how-it-works hint. No file paths or module names; use UI labels.
- [x] 3.3 Regenerate screenshots with `node scripts/screenshots.mjs` and verify `node scripts/screenshots.mjs --axe` has no new contrast failures; update `site/.vitepress/config.ts` sidebar if needed (no new page expected).

## 4. Validation

- [x] 4.1 Run `mix precommit` and `openspec validate --strict` and fix issues.
