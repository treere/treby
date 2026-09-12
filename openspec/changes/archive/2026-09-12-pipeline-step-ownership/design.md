## Context

The job detail page (`TrebyWeb.JobsLive.Show`) is the daily workspace: description, details, candidates grouped by stage, and a Pipeline section. The Pipeline section has two modes: a read-only overview (default) and an admin-only editor behind "Manage Pipeline". Roles are stored per `PipelineStage` as three join tables: `pipeline_stage_examiners`, `pipeline_stage_reviewers`, `pipeline_stage_advancers`. Today the overview at `show.ex:502` renders badges `E`/`R`/`A` with user names only when assignments exist (guard `examiners != [] or ...` at `show.ex:527`); empty stages render no ownership line. Manage mode shows compact counts (`2E`) at `show.ex:667-675`. No legend explains E/R/A. Permission gating (`can_manage_stage?` at `show.ex:1512`) allows anyone to move candidates in non-interview stages, but only advancers (or admins) in interview stages — not explained in UI. The Kanban board (`PipelineLive.Index`) has its own permission hint (opacity + tooltip) but the job detail overview does not.

Stakeholders: hiring managers, recruiters, admins, candidates (indirectly). Multi-tenant isolation already enforced via `tenant_id` scoping in `Pipeline.Stages`.

## Goals / Non-Goals

**Goals:**
- Every stage in the job-detail pipeline overview always shows who is responsible, with an explicit "Everyone" fallback when no one is assigned.
- Remove cryptic single-letter abbreviations or make them self-explanatory with a visible legend.
- Add a concise "how the pipeline works" explainer co-located with the Pipeline section.
- Keep the editor consistent with the overview (same ownership semantics).

**Non-Goals:**
- Changing the pipeline data model, role semantics, or permission rules (roles and `can_manage_stage?` stay as-is).
- Redesigning the Kanban board itself — board header ownership is out of scope unless trivial to align.
- Introducing per-role default-ownership configuration (e.g., "default advancer for new stages").

## Decisions

**D1 — Scope: job detail overview first, board later.**
- Do the job detail overview + editor. Leave the Kanban board column header ownership for a follow-up. Rationale: the reported confusion is on the job detail page; board already has its own permission affordance and is a larger surface to QA. Alternative (do both now) considered and rejected to keep diff small.

**D2 — "Everyone" as the empty-state label.**
- When all three role lists are empty, render `Responsible: Everyone` (i18n: `gettext("Everyone")`, Italian locale `Tutti`). When some roles are populated, render only populated roles with full labels, e.g. `Advancers: Luca Bianchi, Anna Rossi` and omit empty roles. Alternative "Everyone (no restriction)" was considered but longer; "Tutti" alone was requested. Choose short, localized string.

**D3 — Replace `E`/`R`/`A` prefixes with full labels + legend.**
- Current: `<span>E</span>name`. New: `Advancer: name` or badge with icon + label. Add a single legend line above the stage list: `Examiner — runs interviews · Reviewer — reviews · Advancer — moves candidates`. Rationale: E/R/A is undocumented jargon; full labels cost little horizontal space and pass a11y. Alternative (keep letters + tooltip) is less discoverable; chosen full labels with legend line.

**D4 — Explainer placement.**
- Add subtitle under the Pipeline heading and a small info hint: `"Stages are ordered top-to-bottom. Interview stages require an Advancer to move candidates. Editing stages here creates a pipeline copy for this job only."` Keep it 2–3 sentences, collapsible via `<details>` if it feels noisy. Alternative (separate help modal) rejected as over-engineered for this change.

**D5 — i18n.**
- Use `gettext` for all new strings (`Everyone`, `Responsible`, role labels, legend, explainer). Italian translations via existing `priv/gettext` flow. No hardcoded Italian in templates.

**D6 — No new components.**
- Reuse existing `TrebyWeb.DesignSystem` badges and Tailwind tokens; no new design-system component. Ownership line is plain flex + badges.

## Risks / Trade-offs

- **"Everyone" misreads as explicit assignment** → Mitigation: wording + legend clarifies empty means unrestricted; editor still shows empty lists correctly. Tooltip on the line can say "No one assigned — anyone can act (interview stages still need an Advancer if specified)".
- **Legend takes vertical space / noise** → Mitigation: single muted line (`text-xs text-zinc-500`) above the list; verify in light + dark via `node scripts/screenshots.mjs --axe`.
- **Editor/Overview divergence** → Mitigation: both branches read from `stages_with_overview` (already has examiners/reviewers/advancers); editor's `stages_with_counts` will also render names or a shared helper, not just counts.
- **Translation gap** → Mitigation: add `gettext` strings even if Italian `.po` lags; fallback is English `Everyone`.

## Migration Plan

- No DB migration.
- Deploy: normal release. No feature flag needed (UI-only).
- Rollback: revert templates.
- Docs: update `site/features/pipeline.md` Pipeline Overview and Per-Stage Permissions sections, regenerate screenshots.

## Open Questions

- Should the Kanban board column header also show the same `Responsible: Everyone / Names` line for consistency? Deferred to follow-up — confirm before closing this change.
- Exact wording for the "how it works" hint — finalize during implementation review (keep under 3 sentences).
