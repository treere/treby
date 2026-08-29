# Proposal: Fix delete confirmation modal

## Why

The `<.confirm_modal>` component renders its slot content (the message paragraph and the footer buttons) only on the initial socket render and never patches it afterward, because `CoreComponents.confirm_modal/1` hands `Pattern.confirm_dialog/1` an assigns map with a forced empty `__changed__`. As a result every confirmation dialog opens with a **blank message**, and on the Candidates index the confirm button is stuck with the default `phx-click="confirm_delete"` instead of the actual delete action. Clicking it sends `confirm_delete %{"id" => ..., "value" => ""}`, which matches no `handle_event` clause and crashes the LiveView with a `FunctionClauseError` — deleting the candidate is impossible.

## What Changes

- Fix `CoreComponents.confirm_modal/1` so the confirmation dialog's slot content (message text and confirm-button wiring) is re-rendered whenever `confirm_delete` changes, instead of being frozen at mount time.
- Make the Candidates index confirm button wire to `do_delete_candidate` (static `on_confirm`, matching every other LiveView) so the delete action executes regardless of the diff behavior.
- Add a defensive `handle_event("confirm_delete", %{"id" => id}, socket)` clause in the Candidates index that performs the delete, so an id-only payload can never crash the LiveView.
- All confirm dialogs now display the intended warning message (e.g. "Are you sure you want to delete Alice Johnson? This action cannot be undone.").

## Capabilities

### New Capabilities
<!-- None -->
- (none)

### Modified Capabilities
- `delete-confirmations`: The confirmation modal MUST display the current `confirm_delete` message and MUST wire the confirm button to the intended delete action for every delete flow. The single-entity delete flow must execute the deletion when confirmed instead of crashing.

## Impact

- `lib/treby_web/components/core_components.ex` — `confirm_modal/1` assigns construction.
- `lib/treby_web/live/candidates_live/index.ex` — modal `on_confirm` attribute and a new `confirm_delete` handler clause.
- All LiveViews relying on `<.confirm_modal>` benefit from the message fix (team invitations, fields, sources, pipeline, scorecards, email templates, availability, candidates show).
- No database or API changes.