## Why

Pipeline shows `cursor-move` but `move_candidate` checks `user_is_advancer?` only after drop, failing silently. Job form shows duplicate pipeline names `Default pipeline` + `Default` (seeded twice) and saves `pipeline_id == nil` if the duplicate is selected, later crashing `list_pipeline_stages(nil)`. Permissions and naming are invisible.

## What Changes

- Disable drag handle and show tooltip `Only stage advancers can move` when `user_is_advancer? == false` (pre-check, not post-drop).
- Deduplicate pipeline seed: ensure single `Default` pipeline per tenant; job form lists one option and defaults to `default_pipeline_id`.
- Validate `pipeline_id` on job save (fallback to default if nil).

## Capabilities

### New Capabilities
- (none)

### Modified Capabilities
- `pipeline`: Visibility of advancer permission pre-drag.
- `pipeline-stage-roles`: UX for advancer check.

## Impact

- `lib/treby_web/live/pipeline_live/index.ex` — drag handle + `can_move?` guard.
- `lib/treby/tenants/tenants.ex` — seed dedup, `JobsLive.Index` default.
- No DB migration (seed fix).
