## Why

On a fresh tenant (`Friction Co 86`) the pipeline Interview card shows a `Scorecard` button even though `Treby.Scorecards.get_active_template/1` returns `nil`. Clicking it in `PipelineLive.Index` crashes with `BadMapError expected a map, got: nil` at `handle_event "open_scorecard"` (`pipeline_live/index.ex:1026` does `template.criteria` without nil guard). This blocks `Interview → Advance` because `ready_to_advance?` requires all scorecards, and the scorecard cannot be opened. New tenants hit this before discovering `Settings → Scorecards`.

## What Changes

- Guard the scorecard path in `TrebyWeb.PipelineLive.Index`:
  - In `handle_event "open_scorecard"`, fetch `get_active_template`; if `nil`, `put_flash(:error, "No scorecard template configured — create one in Settings → Scorecards")` and return without assigning `show_scorecard_form`.
  - On the board, disable or hide the `Scorecard` button when no active template exists for the tenant, with tooltip linking to settings.
  - Optionally auto-create a minimal default template on tenant creation (`Treby.Tenants.create_tenant`) to avoid zero-state entirely — deferred to `design.md` decision.
- Keep existing `Pipeline.ready_to_advance?` / `all_scorecards_completed?` semantics; only harden the UI entry point.

## Capabilities

### New Capabilities
- _None_ — hotfix/UX guard.

### Modified Capabilities
- `interview-scorecards`: Scorecard action SHALL be disabled with guidance when no active template exists, instead of crashing; opening a scorecard SHALL handle `nil` template gracefully.

## Impact

- Affected code: `lib/treby_web/live/pipeline_live/index.ex` (`open_scorecard` handler + card render guard), optionally `lib/treby/scorecards/scorecards.ex` and `lib/treby/tenants/tenants.ex` for default-template seeding
- No migration. No new deps.
- Tests: add case in `test/treby_web/live/pipeline_live_test.exs` for scorecard click with no template asserting flash/ no crash.
