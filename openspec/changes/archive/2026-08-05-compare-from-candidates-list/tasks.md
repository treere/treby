## 1. Routing and Navigation

- [x] 1.1 Move the compare route from `/compare` to `/candidates/compare` (before the `/candidates/:id` catch-all) and remove the old `/compare` route in `lib/treby_web/router.ex`
- [x] 1.2 Remove the "Compare" link from the desktop nav menu in `lib/treby_web/components/layouts.ex`
- [x] 1.3 Remove the "Compare" link from the mobile nav drawer in `lib/treby_web/components/layouts.ex`

## 2. Comparison View

- [x] 2.1 Read candidate ids from the `?ids=` URL param in `ComparisonLive.Index.mount/3`, split on comma, and run `Treby.Comparison.compare_candidates/1` immediately
- [x] 2.2 Render the side-by-side grid directly from the mount result and add a "← Back to candidates" link to `/app/candidates`
- [x] 2.3 Remove the on-page candidate-selection UI and the `toggle_candidate`, `compare`, and `clear_comparison` handlers; show an empty/error state when no valid ids are provided
- [x] 2.4 Drop the now-unused `Candidates` alias and `list_candidates/1` call

## 3. Candidates List Bulk Actions

- [x] 3.1 Add `<option value="compare">Compare</option>` to the bulk action dropdown
- [x] 3.2 Add a "Compare" confirm button gated on `@bulk_action == "compare"` alongside the existing Merge button
- [x] 3.3 Add `bulk_execute_compare` handler that joins `selected_ids` and `push_navigate`s to `/app/candidates/compare?ids=...`
- [x] 3.4 Fix the broken action selects by wrapping the action and stage `<select>` elements in plain `<form>` tags while keeping `phx-change` on the selects

## 4. Tests

- [x] 4.1 Add a test that selecting "Compare" in the bulk bar shows the Compare button
- [x] 4.2 Add a test that clicking Compare navigates to the compare URL with the selected ids
- [x] 4.3 Add `test/treby_web/live/comparison_live_test.exs` covering the table rendered from URL ids and the empty state without ids
- [x] 4.4 Run the full suite and `mix precommit`
