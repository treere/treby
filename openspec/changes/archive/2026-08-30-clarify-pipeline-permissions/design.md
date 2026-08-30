## Context

Pipeline movement is the daily action but permissions are invisible. `PipelineLive.Index` checks `Pipeline.user_is_advancer?` or `admin` only after drop, showing `cursor-move` beforehand. Advancers are assigned in `Settings → Pipeline → Stage → Advancers` but never surfaced on the board. Job creation shows duplicate `Default pipeline` + `Default`.

## Goals / Non-Goals

**Goals:**
- Show per-stage advancer avatars and per-card Move affordance with allowed targets.
- Deduplicate pipeline selector.

**Non-Goals:**
- No role model change.

## Decisions

**Decision 1 — Move dropdown + stage header avatars.**
- Add `Move to` dropdown of allowed targets + stage header with advancer names.
- Keep Sortable for allowed moves, show `not-allowed` cursor otherwise.

**Decision 2 — Deduplicate pipeline select.**
- Single `Default — 7 stages` entry, prompt "Select pipeline".

## Risks / Trade-offs

- **[Risk] Extra query per stage** → Mitigation: preload advancers once per mount.

## Migration Plan

- No migration.

## Open Questions

- None.
