### Requirement: Confirmation modal component
The system SHALL provide a `<.confirm_modal>` function component in core_components.ex that renders a centered overlay dialog with a title, message, cancel button, and confirm button.

#### Scenario: Modal renders when confirm_delete assign is set
- **WHEN** the `confirm_delete` assign is set to a map with `:id`, `:title`, and `:message`
- **THEN** a modal dialog renders with the specified title and message, a "Cancel" button, and a "Confirm" button styled in red

#### Scenario: Modal is dismissed on cancel
- **WHEN** the user clicks the "Cancel" button or presses Escape
- **THEN** the modal closes and the `confirm_delete` assign is set to `nil`

#### Scenario: Confirmation triggers the delete action
- **WHEN** the user clicks the "Confirm" button
- **THEN** the modal closes and a `confirm_delete` event is sent to the server with the deletion identifier

### Requirement: Delete actions require confirmation
All delete actions that permanently remove data SHALL require user confirmation via the modal before executing.

#### Scenario: Single entity delete shows confirmation
- **WHEN** user clicks a "Delete" button for a single entity (candidate, field, template, source, pipeline, rule, note, team member, invite)
- **THEN** a confirmation modal appears showing the entity name and a warning message
- **AND** the deletion does NOT execute until the user confirms

#### Scenario: Bulk delete shows confirmation
- **WHEN** user selects "Delete" from the bulk action dropdown and clicks "Delete"
- **THEN** a confirmation modal appears showing the count of items to be deleted
- **AND** the deletion does NOT execute until the user confirms

#### Scenario: Confirmed deletion executes
- **WHEN** user confirms the deletion in the modal
- **THEN** the original delete logic executes (entity is removed, flash message shown, list refreshed)

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
