## Why

Dismissing a merge suggestion on the merge center currently only hides it for the current page session: the dismissal lives in an in-memory `MapSet`, so the suggestion reappears on reload and the candidates list keeps showing a "Duplicates" badge. Dismissals should be a persistent, per-tenant decision.

## What Changes

- Persist dismissed duplicate-suggestion groups per tenant in a new `dismissed_merge_groups` table (keyed by the deterministic group id, recording who dismissed and when).
- The merge center loads dismissed keys on mount and never shows dismissed groups, including after page reloads.
- The candidates list "Duplicates" badge counts only non-dismissed suggestion groups.
- Dismissing is idempotent; dismissals are scoped per tenant.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `candidate-merging`: The "Merge suggestions list" requirement's "Dismiss a suggestion" scenario changes so a dismissed group stays hidden across page loads (persistent), and the duplicate badge on the candidates list reflects dismissed groups.

## Impact

- New migration `create_dismissed_merge_groups` (table + unique index on `tenant_id`, `group_key`).
- New schema `Treby.Candidates.DismissedMergeGroup`.
- `Treby.Candidates` gains `dismiss_merge_group/3`, `list_dismissed_group_keys/1`, and `list_suggestion_groups/1` (dismissal-aware wrapper over `list_duplicate_groups/1`).
- `TrebyWeb.CandidatesLive.Merge` loads dismissals from the DB on mount and persists on the `dismiss_group` event.
- `TrebyWeb.CandidatesLive.Index` computes the duplicates badge from `list_suggestion_groups/1`.
- Tests: context tests in `test/treby/candidates_merge_test.exs`, LiveView tests in `test/treby_web/live/candidates_merge_live_test.exs`.
