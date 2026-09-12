## Why

On the job detail page the pipeline section does not make it clear who owns each stage or how the pipeline functions. Stages with no examiner/reviewer/advancer assignments show no ownership row at all, and the `E`/`R`/`A` badge abbreviations have no legend — users cannot tell whether "empty" means "everyone" or "unconfigured". This causes confusion about who can move candidates and what each stage is responsible for.

## What Changes

- Make per-stage ownership explicit in the read-only pipeline overview on the job detail page: every stage always shows a responsibility line. If no specific users are assigned, show `Everyone` (localized as `Tutti` in Italian) instead of an empty gap.
- Replace cryptic `E`/`R`/`A` single-letter prefixes with full role labels (`Examiner`, `Reviewer`, `Advancer`) and add a one-line legend above the overview explaining the three roles.
- Add a short explainer for how the pipeline works: ordered stages, what each `stage_type` means, and that edits on the job page create a job-dedicated pipeline copy (not affecting other jobs). Shown as a collapsible hint / subtitle in the Pipeline section and reflected in updated user documentation.
- Align the manage-mode stage list to the same ownership display (names + fallback) so overview and editor never contradict.
- Update user-facing docs (`site/features/pipeline.md` and screenshots) to document the ownership line and the "how it works" hint.

## Capabilities

### New Capabilities
- (none — no new top-level capability; this refines existing pipeline UX)

### Modified Capabilities
- `pipeline`: clarify per-stage ownership visibility and the "Everyone" fallback in Kanban/pipeline contexts (board view + job detail overview).
- `job-pipeline-editor`: make the read-only overview on the job detail page always show an explicit owner line and a roles legend; add pipeline-how-it-works explainer in the job detail Pipeline section; keep editor ownership display consistent.

## Impact

- Code: `lib/treby_web/live/jobs_live/show.ex` (read-only `pipeline_overview` rendering and `stages` editor rendering), optional small helper for ownership label; `lib/treby_web/live/pipeline_live/index.ex` only if board header ownership hint is included (out of scope for job-detail-only variant — documented in design decision).
- No schema/migration changes, no new dependencies.
- Docs/site: `site/features/pipeline.md`, `site/.vitepress/config.ts` (if sidebar changes), `site/features/index.md` (if needed), plus screenshot regeneration via `node scripts/screenshots.mjs`.
- Tests: LiveView tests for job detail pipeline overview ownership line and legend.
