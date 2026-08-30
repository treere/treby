## Context

Pipeline board shows cursor-move but move_candidate checks user_is_advancer? only after drop, silent fail. Duplicate Default pipelines cause nil selection.

## Goals

- Pre-check advancer permission in render: disable drag and show tooltip "Only stage advancers can move" when not advancer and not admin.
- Seed dedup already done; ensure job form defaults correctly.

## Decisions

- In PipelineLive.Index render, compute `can_move = current_user.role=="admin" or Pipeline.user_is_advancer?(stage, current_user.id)` per stage; when false add `title` tooltip and `pointer-events-none` or `cursor-not-allowed` styling to stage column; card drag handle reflects permission.
- No migration.

## Risks

- Over-restrictive disable may block admin → Mitigate admin bypass.
