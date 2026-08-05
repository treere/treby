## Why

The Compare page (`/app/compare`) is a standalone page whose only purpose is selecting candidates to compare — but selection already exists on the candidates list (checkboxes + bulk action bar). A dedicated selection page is redundant: recruiters select candidates in the list and expect to compare them from there. On top of that, the bulk action dropdown has never worked in the real browser (the `phx-change` selects were not inside a `<form>`), so the actions bar appears broken.

## What Changes

- **Compare moves into the candidates list**: the bulk action bar gains a "Compare" action. Selecting 2-3 candidates and choosing Compare navigates to the comparison view with the candidate ids in the URL (`/app/candidates/compare?ids=...`).
- **Comparison page becomes a pure view**: `/app/candidates/compare` renders the side-by-side comparison immediately from the ids in the URL, with a "← Back to candidates" link. Its own candidate-selection UI is removed. Without valid ids it shows an empty state.
- **Compare removed from navigation**: the "Compare" link is removed from the desktop and mobile nav menus. The comparison view is reachable only through the candidates list action.
- **Bulk action bar bug fixed**: the action `<select>` elements are wrapped in `<form>` so `phx-change` events actually fire in the browser — restoring the intended "pick an action, then confirm" flow for Move, Mark Reviewed/New, Send Email, Merge, Delete and the new Compare.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `candidate-comparison`: comparison is initiated from the candidates list bulk action (not from a dedicated selection page); the comparison view reads preselected candidate ids from the URL and renders immediately; without ids it shows an empty state instead of a selection UI.
- `bulk-operations`: the floating action bar gains a "Compare" action that navigates to the comparison view with the selected candidate ids; the action dropdown selection flow is fixed so actions reveal their confirm buttons in real browsers.
- `app-navigation`: the "Compare" menu link is removed from the desktop and mobile navigation.

## Impact

- **Router**: `/compare` route removed; `/candidates/compare` added (before the `/candidates/:id` catch-all).
- **LiveViews**: `ComparisonLive.Index` rewritten to read `?ids=` from URL params and drop selection/`toggle_candidate`/`compare`/`clear_comparison` events; `CandidatesLive.Index` gains the Compare option/button, a `bulk_execute_compare` handler using `push_navigate`, and the form-wrapped action selects.
- **Layout**: `layouts.ex` desktop and mobile nav lose the Compare link.
- **Context**: `Treby.Comparison.compare_candidates/1` is unchanged and reused as-is.
- **Tests**: new tests for the Compare bulk action (button appears; navigation to compare URL) and for the comparison view (table rendered from URL ids; empty state without ids).
- **Site documentation**: no feature page covers compare today; no docs/screenshot updates needed.
