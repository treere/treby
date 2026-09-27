## Context

Most LiveViews copy card, input, table, modal, and badge markup inline instead of using `TrebyWeb.DesignSystem.*` and core components. The proposal counts ~40 card copies, ~40 input copies, 12 raw tables, 4 raw modals, and ~100 repeated status-to-variant mappings. This causes visual drift, doubles theme fixes, and weakens the existing guardrail (`Mix.Tasks.Treby.CheckDesignSystem`, wired into `mix precommit` → pre-push → CI), which currently only scans for hardcoded button/badge colors (`bg-blue-600`, `bg-green-600`, `bg-gray-500`, etc.).

Existing building blocks (no new dependencies):
- `Card.card/1`: `variant` (`default`/`bordered`/`elevated`/`flat`), `header`/`inner_block`/`footer` slots, `class` + `rest` passthrough. Already themed (`bg-white dark:bg-zinc-800 rounded-xl border ...`).
- Core `input/1` + `DesignSystem.input_classes/1`, `select_classes/1`, `textarea_classes/1`: theme-aware form tokens. `Pattern.filter_bar` / `form_section` for groups.
- Core `table/1`: `id`, `rows`, `row_id`, `row_click`, `row_item`, `:col` (`label`), `:action` slots. Already handles `LiveStream` (`phx-update="stream"`) and dark tokens.
- `Modal.modal/1`: `id` (required), `show`, `title`, `size` (`sm`/`md`/`lg`/`xl`), `close_event`, `inner_block`/`footer` slots. `Pattern.confirm_dialog/1`: wraps modal with `title`, `message`, `confirm_label`/`cancel_label`, `confirm_variant` (`primary`/`danger`), `on_confirm`, `on_cancel`, `extra_attrs`.
- `Badge.badge/1` + `DesignSystem.badge_classes/1`: `variant` (`default`/`success`/`warning`/`danger`/`info`), `dot`, `class` + `rest` passthrough.
- Verification: `node scripts/screenshots.mjs` captures all pages in light theme plus `25-dark-mode.png` (sets `phx:theme` to dark); `--axe` runs axe-core serious/critical checks.

## Goals / Non-Goals

**Goals:**
- Migrate all card, input, table, modal, and badge call sites to the components above with zero visual change in light and dark themes.
- Centralize status-to-variant mapping so no LiveView maps statuses inline.
- Extend `check_design_system` so copied markup outside `design_system/*` fails `mix precommit`.

**Non-Goals:**
- No new design tokens, no visual redesign, no dark-theme color changes beyond what the DS already defines.
- No new DS components unless a gap is proven during migration (then add to `design_system/*` once, not per screen).
- No DB migrations, API changes, or new dependencies.

## Decisions

### D1. Card — reuse `<.card>`, no new API
Use `<.card variant={...}>` with `<:header>` / `<:footer>` slots. Mapping:
- Default content panels → `variant="default"`.
- `bordered` only where current copy uses a stronger border (`border-zinc-300`); `elevated` (`shadow-md`) only for dashboard/portal highlights; `flat` for nested cards inside an already-bordered panel.
- Extra spacing via `class` passthrough, extra attrs via `rest`. No new size/padding attrs.
- Alternative considered: new `padded`/`compact` variants. Rejected — one-off spacing belongs in `class`, not in the DS API.

### D2. Input — reuse core `<.input>` + `input_classes`, no new field component
- `to_form/2`-driven `<.input field={@form[:x]} type=...>` everywhere a form object exists (scorecard, import, filters with forms).
- Bare `<input>`/`<select>`/`<textarea>` without a form (filter bars, pipeline search) → keep the tag but take classes only from `DesignSystem.input_classes/1` (or `select_classes`/`textarea_classes`).
- Field groups → `Pattern.form_section` (titled groups) and `Pattern.filter_bar` (filter rows with `on_change`/`on_reset`).
- Alternative considered: new `DesignSystem.Field` component. Rejected — core input is already themed; a second input API doubles maintenance.

### D3. Table — reuse core `<.table>`, raw `<table>` deleted
Map each raw `<table>` to `<.table id rows row_id row_click :col :action>`:
- `id` stays the existing DOM id (stream containers rely on it); `rows` passes the existing assign/stream through unchanged so `phx-update="stream"` keeps working.
- Each `<th>`/`<td>` column becomes `<:col :let={row} label="...">`; row actions become `<:action>`.
- No new table props (no sortable/paginated variant in this change; sorting stays in `FilterBar` + query).
- Alternative considered: `DesignSystem.Table` wrapper. Rejected — core table already carries the DS shell (`rounded-xl border ... bg-white dark:bg-zinc-800`); a wrapper adds indirection for zero styling gain.

### D4. Modal — reuse `<.modal>` + `<.confirm_dialog>`, no new API
- Generic dialogs (scorecard form, pipeline, candidate show, layouts) → `<.modal id show={...} title={...} size={...} close_event={...}>` with `<:footer>` for actions. `size`: keep current width intent (`sm` confirm-like, `md` default, `lg` forms, `xl` wide previews).
- Destructive/confirm flows → `Pattern.confirm_dialog` with `confirm_variant="danger"` (deletes, merges, removals) or `"primary"` (non-destructive confirms), `on_confirm` = existing confirm event, `extra_attrs` = existing `phx-value-*` ids. `on_cancel` = existing close event, else default `close-modal`.
- Keep existing `close_event`/`on_cancel` event names verbatim so server `handle_event` clauses are untouched.
- Alternative considered: extending modal with `dismissable`/`persistent` flags. Rejected — current `close_event=nil` default (push `close-modal` + hide) already covers both cases.

### D5. Badge — add one mapping, delete all per-screen copies
- Add `DesignSystem.status_variant/1` (status string/atom → `"default" | "success" | "warning" | "danger" | "info"`) plus a thin `<.status_badge status={...} label={...} dot={...}>` that renders `<.badge variant={status_variant(status)}>`.
- All ~100 inline `case status do ... "emerald" ... "amber" ...` maps and the `candidate_portal_live` duplicate collapse to `<.status_badge>`. Custom one-off colors pass `variant` directly to `<.badge>`; no ad-hoc `bg-emerald-50 text-emerald-700`-style spans outside `design_system/*`.
- Alternative considered: keep per-domain maps (jobs vs. candidates). Rejected — that is the current drift source; one function is the point of the change.

### D6. Guardrail — extend `@patterns` in place, no new tooling
Extend `Mix.Tasks.Treby.CheckDesignSystem` (`lib/mix/tasks/treby.check_design_system.ex`):
- New named patterns (each reported as `file: pattern-name` for actionable errors):
  1. `copied-card-shell`: `bg-white dark:bg-zinc-800 rounded-xl border` outside DS.
  2. `raw-table`: `<table[ >]` outside DS/core.
  3. `raw-modal-shell`: `fixed inset-0 z-50` (or `bg-black/50` backdrop + `max-h-\[85vh\]`) outside DS.
  4. `raw-input`: `<(input|select|textarea)[^>]*class=` not accompanied by `input_classes|select_classes|textarea_classes|filter_bar|<.input` in the same file.
  5. `copied-badge`: `bg-(emerald|amber|red|blue)-(50|950).*text-(emerald|amber|red|blue)` or `badge.*variant.*case|case.*status.*emerald` style inline maps.
- Keep `@exclude_regex` on `lib/treby_web/components/design_system/`; also exclude `assets/css/app.css` (already the case by file glob). Keep scanning `lib/treby_web/**/*.{ex,heex}`.
- No hook/CI changes needed: the task already runs in `mix precommit` (see `mix.exs:119`), which `scripts/hooks/pre-push` and CI invoke. Only the failure message changes (point at `Button`/`Badge`/`Card`/`Modal`/`Pattern` + `input_classes`/`status_badge`).
- Guardrail lands FIRST and is kept red-tolerant during migration (run with `--allow-fail` locally or land it with the final wave) so intermediate states do not block pushes; final state must be green.

### D7. Migration order — badge → table → card → input → modal
Wave order minimizes risk and maximizes early payoff:
1. **Badge mapping** (`DesignSystem.status_variant` + `status_badge`, delete portal duplicate). Smallest diff, unblocks table/card waves that embed badges.
2. **Tables** (`jobs_live/index`, `candidates_live/index`, `settings_live/team`, `settings_live/audit_log`, `settings_live/webhooks`). Highest visual payoff per file; `row_id`/`row_click`/streams verified per screen.
3. **Cards** (`jobs_live`, `candidates_live`, `settings_live/*`, portal/careers leftovers). Bulk mechanical swap; variant choice per D1.
4. **Inputs** (`scorecard_form`, `pipeline_live`, `candidates_live/index` filters, `import_live`). Includes filter-bar regrouping; highest regression surface (form events), so after the mechanical waves.
5. **Modals** (`scorecard_form`, `pipeline_live/index`, `candidates_live/show`, `layouts`). Last — close-event/Escape/backdrop behavior needs per-dialog testing.
- Within each wave: migrate one screen, run its LiveView tests, regen screenshots, diff light + dark, then move on. Do not mix waves in one commit.

### D8. Dark-mode verification — screenshots script as-is, plus `--axe`
- `node scripts/screenshots.mjs` after every wave: captures all pages light + `25-dark-mode.png` (dark via `phx:theme`). Before/after image diff must show zero unintended changes.
- `node scripts/screenshots.mjs --axe` on the final wave (and any wave touching inputs/modals): fails the wave on serious/critical contrast violations (e.g. `color: inherit` on dark surfaces, missing `dark:` text colors).
- No script changes. New pages need no new screenshot definitions unless migration adds a route (it does not).

## Risks / Trade-offs

- [Risk] Mechanical swaps introduce subtle visual drift (padding, borders) → Mitigation: per-wave screenshot before/after diff; `class` passthrough preserves one-off spacing instead of forcing variant fit.
- [Risk] Modal close behavior changes (backdrop/Escape events) → Mitigation: keep event names verbatim per D4; manually open/close each migrated dialog in both themes.
- [Risk] Table stream/row-click regressions (`row_id`, `phx-update="stream"`) → Mitigation: reuse existing `id`/`rows` assigns; run LiveView tests per screen.
- [Risk] Guardrail false positives on legitimately custom markup → Mitigation: named patterns with clear messages; escape hatch is moving the pattern into `design_system/*`, not inline suppression.
- [Trade-off] Landing the guardrail before migration means a red intermediate state → accepted; run it advisory until the last wave, then enforce green in `mix precommit`.

## Migration Plan

1. Land `status_variant/1` + `status_badge`, migrate all badge call sites, delete portal duplicate.
2. Migrate tables (wave 2), then cards (wave 3), inputs (wave 4), modals (wave 5) per D7.
3. Extend `check_design_system` patterns per D6; run advisory during waves 1–4, enforce green after wave 5.
4. Regen screenshots after each wave; final `node scripts/screenshots.mjs --axe` + `mix precommit` green.
5. Rollback: each wave is independently revertible (one commit per screen); guardrail change reverts with its single commit.

## Open Questions

- Exact canonical status vocabulary for `status_variant/1` (which raw strings exist across jobs/candidates/pipeline?) — enumerate during wave 1.
- Any card/input/table/modal copy that genuinely does not fit the DS API (candidate for a DS addition rather than a forced fit) — flag during its wave, do not invent variants inline.
