## Context

`PipelineLive.Index` Interview cards (`lib/treby_web/live/pipeline_live/index.ex`) show a `Scorecard` button whenever `examiner_interview_for_card(application, current_user.id)` returns an event (i.e. the current user is an examiner for that interview). The handler:

```elixir
def handle_event("open_scorecard", %{"event_id" => event_id}, socket) do
  template = Scorecards.get_active_template(tenant.id)
  criteria = template.criteria  # ← nil when no template → BadMapError
  existing = get_scorecard_for_interview(event_id, user.id)
  ...
end
```

`Treby.Scorecards.get_active_template/1` returns `nil` on a fresh tenant (e.g. `Friction Co 86` before any `ScorecardTemplate` in `Settings → Scorecards`). The board still renders `Scorecard` because the examiner check is independent of the template existence, so clicking it raises `BadMapError expected a map, got: nil` at `template.criteria`. This blocks `Pipeline.ready_to_advance?` which requires all scorecards, so the candidate (`Alice Dome` Interview → Offer) can never advance.

Current `Scorecards` has no default seeding at tenant creation (unlike `Pipeline.create_default_pipeline_stages`), and the `Scorecard` button is not disabled when `template == nil`. The `ScorecardTemplate` changeset requires `criteria` with `valid_types ~w(number_1_5 yes_no_maybe text)` and `name`.

## Goals / Non-Goals

**Goals:**
- Clicking `Scorecard` when no active template exists does not crash; the user sees a guidance flash or disabled state.
- The board indicates the zero-state (`No scorecard template → create in Settings → Scorecards`) so the advance gate is discoverable.
- `Ready to advance` semantics unchanged; only the entry point is hardened.

**Non-Goals:**
- No migration to backfill templates for all existing tenants (decision is runtime guard + optional seeding for new tenants).
- No change to `ready_to_advance?` aggregation or Oban/scorecard storage.
- No `site/` doc changes beyond what `proposal` already notes.

## Decisions

**Decision 1 — Guard `open_scorecard` with nil check (chosen) over auto-creating a template on the fly.**
- *Chosen:* At top of `handle_event "open_scorecard"`, if `template == nil` → `put_flash(:error, "No scorecard template configured — create one in Settings → Scorecards")` and `{:noreply, socket}` without assigning `show_scorecard_form`.
- *Why:* Minimal, explicit, fails open with guidance. Matches the `proposal`'s "disable with guidance" and avoids hidden side effects.
- *Alternative:* Auto-create a minimal template (`name: Default, criteria: [%{name: "Overall", type: "number_1_5"}]`) when `nil` — deferred to Decision 3 for new tenants only; for existing tenants, auto-create would be surprising.

**Decision 2 — Disable/hide `Scorecard` button on the board when no template (chosen: guard + tooltip).**
- *Chosen:* In the card render, fetch `active_template = Scorecards.get_active_template(tenant.id)` (or cached assign) and if `nil`, render `Scorecard` as disabled with `title="No template — Settings → Scorecards"` and no `phx-click`.
- *Why:* Prevents the click that would crash; makes the zero-state visible without navigating.
- *Alternative:* Keep button enabled but handle error in handler only — less discoverable; user clicks then sees flash.

**Decision 3 — Seed a default template at tenant creation (optional, not blocking).**
- *Chosen:* In `Treby.Tenants.create_tenant` after `create_default_pipeline_stages`, create a default `ScorecardTemplate` (`name: Default, criteria: [%{name: "Overall", type: "number_1_5"}]`) if none exists.
- *Why:* Fresh tenants like `Friction Co 86` never hit the guard. This mirrors pipeline seeding.
- *Alternative:* Seed only on first `get_active_template` miss (lazy) — more complex; tenant creation is the natural place.

## Risks / Trade-offs

- **[Risk] Template created after the guard but before click → race where button still disabled until reload** → Mitigation: board subscribes to `ScorecardTemplate` changes or simply re-enables on next `handle_info`/`mount`; for hotfix, require reload or re-enter pipeline.
- **[Risk] Existing tenants with custom templates but `is_active == false` still `nil`** → Mitigation: `get_active_template` orders by `position` and `limit 1`; if all are inactive, treat as `nil` and show guidance (same as no template).
- **[Risk] Overhead of fetching template per card** → Mitigation: fetch once per mount (`assign :scorecard_template`) and reuse; for hotfix, per-handler fetch is acceptable (single query).

## Migration Plan

- No migration. Deploy: `mix compile`. Rollback: revert guard.

## Open Questions

- Should the guard auto-redirect to `Settings → Scorecards` instead of just flashing? Deferred — flash + disabled button is sufficient for hotfix.
