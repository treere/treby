## Why

Offer stage cards in the pipeline show only `Mark reviewed` even when `Pipeline.current_state` reports `blocked?: false` and `next_actions: [%{kind: :advance}]`. Retest with `UX Retest Co` (`Frank Dome` in `Offer`) confirmed the backend is ready to advance but the UI hides the button, forcing a direct `Pipeline.move_application` bypass. This blocks completing hires via pure UI.

## What Changes

- Render `Advance` (and `Reject`) for `stage_type: "offer"` when `current_state.blocked? == false`, same as `interview` stage.
- Keep `Advance` disabled with tooltip when blocked (missing scorecard / interview not completed) — already handled for other stages.
- Ensure `Hired` is terminal (no `Advance`) and `Rejected` hides `Advance`.

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `pipeline`: Offer stage now exposes `Advance to Hired` when `ready_to_advance?` true.

## Impact

- `lib/treby_web/live/pipeline_live/index.ex` — `card_actions` / `render_stage` conditional for `offer`.
- No DB migration.
- No spec for new capability; delta spec for `pipeline`.
