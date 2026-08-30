## Context

Pipeline board in `lib/treby_web/live/pipeline_live/index.ex` renders stage columns from `Pipeline.list_pipeline_stages_for_job`. Each card shows `card_actions` based on `Pipeline.current_state`. For `Interview` the card shows `Mark as completed` → `Scorecard` → `Advance` when `blocked? == false`. For `Offer` the template omits `Advance` entirely, even though `current_state` returns `next_actions: [%{kind: :advance}]`. Retest confirmed `Offer` → `Hired` is valid via backend but hidden in UI.

Tenant `ux-retest-co` reproduces: `Frank Dome` in `Offer` has `blocked?: false` but card shows only `Mark reviewed`.

## Goals / Non-Goals

**Goals:** Show `Advance` for `Offer` when not blocked; keep disabled+tooltip when blocked; `Hired` remains terminal.

**Non-Goals:** Changing `Offer` business rules (no new blockers); drag-and-drop permissions (separate change).

## Decisions

- Reuse existing `current_state` logic — no new state. Only fix `card_actions` conditional to include `stage_type: "offer"` with same `blocked?` check as `interview`.
- Keep `Reject` visible for `Offer` as before.
- No migration.

## Risks / Trade-offs

- [Risk] `Offer` advancing without offer letter → Mitigation: `Offer` has no extra blockers today; if offer-letter check is added later, `current_state` will handle disabling.
