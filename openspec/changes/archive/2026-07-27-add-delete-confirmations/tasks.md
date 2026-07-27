## 1. Core Component

- [x] 1.1 Add `<.confirm_modal>` function component to `core_components.ex` — accepts assigns: `confirm_delete`, `on_confirm` (event name), `on_cancel` (event name). Renders overlay + dialog with title, message, cancel button, confirm button (red).
- [x] 1.2 Add keyboard handling: Escape closes modal, backdrop click closes modal, focus trap within modal (colocated JS hook if needed, or inline script).

## 2. Candidates LiveViews

- [x] 2.1 `candidates_live/index.ex` — Add `confirm_delete: nil` to mount assigns. Rename `delete_candidate` event to `do_delete_candidate`. Add `confirm_delete` event (sets assign) and `cancel_delete` event (clears assign). Add modal markup in template before closing `</Layouts.app>`.
- [x] 2.2 `candidates_live/index.ex` — Add confirmation for bulk delete: rename `bulk_execute_delete` to `do_bulk_execute_delete`. Wire `bulk_execute_delete` to show modal with count. Update modal to show bulk-specific message.
- [x] 2.3 `candidates_live/show.ex` — Add confirmation for `delete_note` event. Add `confirm_delete: nil` assign, `confirm_delete`/`cancel_delete` events, modal markup.

## 3. Pipeline LiveView

- [x] 3.1 `pipeline_live/index.ex` — Add confirmation for `bulk_execute_delete`. Rename to `do_bulk_execute_delete`, add confirmation flow.

## 4. Settings LiveViews

- [x] 4.1 `settings_live/fields.ex` — Add confirmation for `delete_field`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.2 `settings_live/scorecards.ex` — Add confirmation for `delete_template`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.3 `settings_live/sources.ex` — Add confirmation for `delete_source`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.4 `settings_live/pipeline.ex` — Add confirmation for `delete_pipeline`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.5 `settings_live/availability.ex` — Add confirmation for `delete_rule`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.6 `settings_live/email_templates.ex` — Add confirmation for `delete_template`. Add `confirm_delete: nil` assign, confirmation events, modal markup.
- [x] 4.7 `settings_live/team.ex` — Add confirmation for `remove_user` and `revoke_invite`. Add `confirm_delete: nil` assign, confirmation events, modal markup.

## 5. Verification

- [x] 5.1 Run `mix precommit` and fix any lint/type errors.
- [x] 5.2 Manual verification: confirm modal appears for each delete action and cancellation works.
