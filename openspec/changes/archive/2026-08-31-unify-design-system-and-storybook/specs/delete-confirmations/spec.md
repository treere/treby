## MODIFIED Requirements

### Requirement: Confirmation modal component
The system SHALL provide a confirmation dialog via `TrebyWeb.DesignSystem.Pattern.confirm_dialog/1` (wrapping `TrebyWeb.DesignSystem.Modal`) that renders a centered overlay with title, message, cancel and confirm buttons. When the `confirm_delete` / `show` assign changes, the dialog's message and confirm wiring SHALL re-render to reflect current state (no stale mount-time content). `CoreComponents.confirm_modal` (deprecated shim delegating to the pattern) SHALL NOT be used in new or migrated code.

#### Scenario: Modal renders when confirm_delete assign is set
- **WHEN** the `confirm_delete` assign is set to a map with `:id`, `:title`, and `:message`
- **THEN** a modal dialog renders with the specified title and message, a "Cancel" button, and a "Confirm" button styled via the design system (`btn-error` for danger, `btn-primary` for primary)

#### Scenario: Modal persists if assign not set
- **WHEN** the `confirm_delete` assign is `nil` and the page re-renders
- **THEN** the modal remains closed

#### Scenario: Modal content reflects the current confirm_delete assign
- **WHEN** the `confirm_delete` assign is updated (e.g. after triggering a delete for an entity)
- **THEN** the message paragraph shows the new `message` value
- **AND** the confirm button's `phx-click` targets the configured `on_confirm` action for the current entity
- **AND** the confirm button carries the current `id` as a `phx-value` attribute

#### Scenario: Modal is dismissed on cancel
- **WHEN** the user clicks the "Cancel" button or presses Escape
- **THEN** the modal closes and the `confirm_delete` assign is set to `nil`

#### Scenario: Confirmation triggers the delete action
- **WHEN** the user clicks the "Confirm" button
- **THEN** the modal closes and the configured `on_confirm` event (the actual delete action, e.g. `do_delete_candidate`) is sent to the server with the deletion identifier

#### Scenario: Migrated code uses DesignSystem directly
- **WHEN** any delete flow is inspected after migration
- **THEN** it renders `<.confirm_dialog>` from `TrebyWeb.DesignSystem.Pattern` (or `DesignSystem.Modal`) not `CoreComponents.confirm_modal`

#### Scenario: Storybook documents confirm dialog
- **WHEN** a developer opens the ConfirmDialog story in storybook
- **THEN** controls allow switching `confirm_variant` (`primary`/`danger`), `title`, `message`, and `show`, and the dialog preview matches the modal spec (backdrop, Escape, focus)

### Requirement: Confirmation modal is accessible
The confirmation modal SHALL be keyboard accessible and follow accessibility best practices.

#### Scenario: Escape key closes modal
- **WHEN** the confirmation modal is open and user presses Escape
- **THEN** the modal closes without executing the deletion

#### Scenario: Backdrop click closes modal
- **WHEN** the confirmation modal is open and user clicks the dark backdrop overlay
- **THEN** the modal closes without executing the deletion

#### Scenario: Focus management
- **WHEN** the confirmation modal opens
- **THEN** keyboard focus moves to the confirm button
- **AND** Tab key cycles focus within the modal (trap focus)
