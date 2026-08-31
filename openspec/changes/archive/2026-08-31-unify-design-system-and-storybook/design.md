## Context

Treby's UI is built with Phoenix LiveView + Tailwind CSS 4 + daisyUI themes. A design system was started (`TrebyWeb.DesignSystem`, `assets/css/app.css` tokens, `CoreComponents` shims) but never completed: many screens use ad-hoc classes (`bg-blue-600`, `bg-gray-500`, `bg-gray-50`), raw badge spans, and legacy wrappers (`CoreComponents.confirm_modal`/`empty_state`). Several components exist only as definitions (`Tabs`, `Dropdown`, `Card`, `Avatar`, `Spinner`/`Skeleton`) with almost no consumers. No isolated catalog exists, so regressions and visual drift are hard to catch. The task is to finish the system, migrate 100% of the app to it, and add `phoenix_storybook` as a dev-only catalog.

Constraints from `AGENTS.md`: keep Tailwind import as `@import "tailwindcss" source(none); @source "../css"; @source "../js"; @source "../../lib/treby_web";`, never use `@apply` or inline `<script>` in templates (use ColocatedHook with `.` prefix), wrap every LiveView with `<Layouts.app flash={@flash} current_scope={@current_scope}>`, use `<.icon>` / `<.input>` / `to_form/2`, `phx-update="stream"` for collections, and keep `site/` as a user manual (no code internals).

## Goals / Non-Goals

**Goals:**
- Single source of truth for tokens (spacing, typography, color semantic, radius, shadow) with light/dark values in `assets/css/app.css`.
- Complete, documented component library: Button (variants/sizes/loading/icon/disabled), Badge, Card, Modal, Dropdown, Tabs, Avatar, Feedback (Spinner/Skeleton/Toast), Pattern (ConfirmDialog, PageHeader, EmptyState, FilterBar, FormSection, LoadingOverlay), plus `Table`/`List`/`Header` consolidation.
- 100% migration: no screen renders a primary/danger/ghost button or badge/status outside the DS; no duplicated flash/confirm/empty-state markup.
- `phoenix_storybook` integrated, dev-only, with a story per component/variant, reachable locally without leaking to prod.
- Guardrail preventing regressions (lint/CI rule).

**Non-Goals:**
- Visual redesign or brand change — normalize existing palette, not new branding.
- Replacing daisyUI wholesale in this change beyond token cleanup; full removal is a follow-up.
- Public/hosted storybook; it stays local/dev.
- DB/schema changes.

## Decisions

**1. Keep and normalize existing DS as the base (vs. new library).**
Rationale: ~8 components + tokens already exist and are referenced by `CoreComponents`. Evolving them is lower risk than rewriting. Alternatives considered:引入 shadcn-style CLI or Radix — rejected (React-oriented, adds JS weight, conflicts with LiveView).

**2. Tokens: consolidate in `assets/css/app.css`, semantic daisyUI vars + `--ds-*`.**
- Keep daisyUI theme plugin blocks (`light`/`dark` with `oklch` vars) and add `--ds-*` aliases for spacing/typography/shadow/radius. Remove hardcoded `gray-50/gray-900` usage in portal/layouts, map to `base-100/200/300` + `base-content`.
- Keep tailwind v4 `@source` syntax unchanged.
- Rationale: minimal build change, preserves `phx` dark variant (`[data-theme=dark]`). Alternative (CSS modules / Panda) rejected as churn.

**3. Component API: function components with `attr` + `slot` + `class` + `:rest` passthrough.**
- Follow existing `TrebyWeb.DesignSystem.*` conventions. Props stay serializable for Storybook controls.
- Accessibility: buttons use native `<button>`/`<.link>` switch, `aria-label`, focus-visible, `phx-mounted={JS.focus()}` for modals; Tabs use roving tabindex.
- Variant mapping stays in `TrebyWeb.DesignSystem.variant_classes/1` / `badge_classes/1` / `size_classes/1` so Stories and app share the same source.

**4. `phoenix_storybook` 0.9, dev-only.**
- Dependency: `{:phoenix_storybook, "~> 0.9", only: :dev}` (https://github.com/phenixdigital/phoenix_storybook).
- Module: `lib/treby_web/storybook.ex` implements `PhoenixStorybook.Storybook` with `content_path: "storybook"`, `entries: [storybook/**]`.
- Stories: `storybook/<component>/<component>.story.exs` per component (Button, Badge, Card, Modal, Dropdown, Tabs, Avatar, Feedback/Spinner/Skeleton/Toast, Pattern/*). Use `attr` controls for variants/sizes/boolean flags.
- Routing: mount only in dev — in `lib/treby_web/router.ex` wrap `import PhoenixStorybook.Router` + `scope "/storybook" when Mix.env() == :dev` (or `Application.get_env(:treby, :enable_storybook)`). Verified pattern from `phoenix_storybook` docs; alternative `if Mix.env()` at compile time is equivalent. Fail-closed: prod release has no route, no dependency compiled.
- Assets: storybook reuses `app.css`/`app.js`; no extra bundle. Docs recommend `storybook` folder at project root; we use that.
- Why this lib: native LiveView/HEEx support, controls/playground, no Node. Alternatives (Storybook JS, Histoire, Ladle) require separate frontend build.

**5. Migration strategy: codemod + manual pass + deprecation removal.**
- Phase 1: finalize DS APIs and add Stories (so changes are previewable).
- Phase 2: migrate screens in batches (settings, candidates, jobs, pipeline, portal, auth) — replace `class="bg-blue-600 ..."` / `bg-gray-500` / raw badge spans with DS calls.
- Phase 3: remove `CoreComponents.button/empty_state/confirm_modal` shims (they currently delegate to DS) and fix any remaining imports.
- Tooling: a one-off `mix` task or `rg` replace list, then `mix precommit` + visual check via storybook + screenshots (`node scripts/screenshots.mjs` not required here since `site/` is out of scope, but local `mix test` should cover).

**6. Guardrail.**
- Add a CI check: `grep -R "bg-blue-600.*text-white.*px-3.*rounded" lib/` and `grep -R "bg-gray-500" lib/treby_web --include="*.ex" --include="*.heex"` must return empty, or a Credo check `Treby.Credo.Checks.DesignSystemUsage`. Fail the check if raw button/badge classes appear outside `design_system/*`. Keeps future PRs on the DS.

## Risks / Trade-offs

- **Token normalization breaks dark mode briefly** → Mitigation: keep both `--ds-*` and daisyUI vars, test every page in both themes via storybook + manual `data-theme` toggle; add per-component dark scenario.
- **Mass migration touches ~30 files, merge conflicts** → Mitigation: batch by area, keep commits small, land behind no feature flag (visual-only); `mix precommit` per batch.
- **Storybook adds dev compile time** → Mitigation: `only: :dev` ensures zero prod cost; entry count ~12–15, negligible.
- **Legacy shim removal breaks external links** → Mitigation: `CoreComponents` shims stay deprecated for one release, then removed; search shows no external consumers.
- **DaisyUI vs. no-daisyUI tension in AGENTS.md** → Decision keeps daisyUI theme vars but enforces DS as the only consumer of class names; future change can drop daisyUI plugin entirely.

## Migration Plan

1. Add `phoenix_storybook` dep (`only: :dev`), `storybook.ex`, initial `storybook/**/*.story.exs`, dev-only route; verify `mix deps.get`, `mix compile`, `mix test` pass and `/storybook` 404s in `MIX_ENV=prod`.
2. Normalize `assets/css/app.css` tokens, fix `layouts.ex` / portal `gray-50` → `base-*`, ensure dark variant still works.
3. Harden DS components (missing variants/sizes, a11y, loading/disabled, focus) and add/refresh Stories.
4. Migrate batch 1: `settings_live/*`, batch 2: `candidates_live/*` + `jobs_live/*` + `pipeline_live/*`, batch 3: `candidate_portal_live/*` + controllers/* + `layouts.ex`.
5. Remove `CoreComponents` delegating `button/confirm_modal/empty_state` shims, inline remaining uses to DS imports; run `mix precommit`.
6. Add CI guard (grep/Credo), update `README.md` with `http://localhost:4000/storybook` dev note.
7. Rollback: revert is safe (visual only); storybook mount is dev-only so prod rollback is just code revert, no data migration.

## Open Questions

- Keep `CoreComponents.header/table/list` or consolidate into `DesignSystem.PageHeader`/`Table`? Proposal: consolidate `header` → `PageHeader`, keep `table` in `CoreComponents` but theme via DS tokens until a DS `Table` exists.
- Do we want a DS `Form` wrapper or keep `CoreComponents.input`? Keep `input` in `CoreComponents` for now (heavily used, Ecto-aware), but style via DS input classes.
- Credo custom check vs. simple `grep` CI: start with `grep`, promote to Credo if noisy.
