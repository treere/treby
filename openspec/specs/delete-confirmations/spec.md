# Delete Confirmations

## Purpose

Ensure destructive operations require explicit user confirmation so data cannot be permanently removed by accident.

## Requirements

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

### Requirement: Delete actions require confirmation
All delete actions that permanently remove data SHALL require user confirmation via the modal before executing, and confirming SHALL execute the deletion without error.

#### Scenario: Single entity delete shows confirmation
- **WHEN** user clicks a "Delete" button for a single entity (candidate, field, template, source, pipeline, rule, note, team member, invite)
- **THEN** a confirmation modal appears showing the entity name and a warning message that names the entity
- **AND** the deletion does NOT execute until the user confirms

#### Scenario: Bulk delete shows confirmation
- **WHEN** user selects "Delete" from the bulk action dropdown and clicks "Delete"
- **THEN** a confirmation modal appears showing the count of items to be deleted
- **AND** the deletion does NOT execute until the user confirms

#### Scenario: Confirmed deletion executes
- **WHEN** user confirms the deletion in the modal
- **THEN** the original delete logic executes (entity is removed, flash message shown, list refreshed)
- **AND** the LiveView process does NOT crash

#### Scenario: Cancelled deletion does nothing
- **WHEN** user cancels the confirmation modal
- **THEN** no deletion occurs and the UI returns to its previous state

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
