## 1. Pipeline Offer Advance

- [x] 1.1 Fix `card_actions` in `lib/treby_web/live/pipeline_live/index.ex` to show `Advance` for `offer` when `blocked? == false` (disabled+tooltip when blocked)
- [x] 1.2 Verify `Hired` remains terminal and `Rejected` hides `Advance`

## 2. Tests

- [x] 2.1 Add LiveView test: candidate in `Offer` with `blocked?: false` shows enabled `Advance`; when blocked shows disabled
- [x] 2.2 Run `mix test test/treby_web/live/pipeline_live_test.exs`

## 3. Polish

- [x] 3.1 Sync `openspec/specs/pipeline/spec.md` (already delta), run `openspec validate --strict` and `mix precommit`
