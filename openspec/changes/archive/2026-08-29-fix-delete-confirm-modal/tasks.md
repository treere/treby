# Tasks: Fix delete confirmation modal

## 1. Fix the confirm_modal component

- [x] 1.1 In `lib/treby_web/components/core_components.ex`, replace the hard-coded `__changed__: %{}` in `confirm_modal/1` with `__changed__: nil` so the confirm dialog (including its message slot and footer buttons) re-diffs on every render

## 2. Fix candidates index delete wiring

- [x] 2.1 In `lib/treby_web/live/candidates_live/index.ex`, change the `<.confirm_modal>` `on_confirm` attribute to the static `"do_delete_candidate"` (currently a dynamic `if @confirm_delete, do: ..., else: "confirm_delete"`)
- [x] 2.2 Add a defensive `handle_event("confirm_delete", %{"id" => id}, socket)` clause in `CandidatesLive.Index` (before the existing `%{"id" => id, "title" => title, "message" => message}` clauses) that performs the single-candidate delete instead of crashing

## 3. Tests

- [x] 3.1 Add/extend tests for the candidates index delete flow: clicking confirm on the modal deletes the candidate, the LiveView does not crash, and a test for the id-only `confirm_delete` payload executing the delete
- [x] 3.2 Add a component test asserting `confirm_modal` renders the current `message` and wires the confirm button to the provided `on_confirm`

## 4. Verification

- [x] 4.1 Run `mix test` for the affected test files
- [x] 4.2 Browser-verify via Playwright: candidates index → row Delete → modal shows the full message and confirm button → clicking it deletes the candidate with a success flash and no LiveView crash