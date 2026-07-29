## ADDED Requirements

### Requirement: ConfirmDialog component
The system SHALL provide a `<.ConfirmDialog>` composite component wrapping Modal with a configurable title, message, confirm/cancel button texts, and a callback event on confirmation.

#### Scenario: Confirm dialog renders
- **WHEN** rendering `<.ConfirmDialog id="delete-user" title="Delete user" on_confirm="delete" />`
- **THEN** a modal with the title, confirm button, and cancel button is rendered

#### Scenario: Confirm triggers callback
- **WHEN** user clicks the confirm button
- **THEN** a `"delete"` event is sent with the dialog's id and any extra params

### Requirement: PageHeader component
The system SHALL provide a `<.PageHeader>` component with title, optional subtitle, breadcrumbs, and actions slot.

#### Scenario: Page header with breadcrumbs
- **WHEN** rendering `<.PageHeader breadcrumbs={[...]} title="Users">`
- **THEN** breadcrumbs and title are displayed

### Requirement: EmptyState component
The system SHALL provide an `<.EmptyState>` component with icon, title, description, and action slot (for a CTA button).

#### Scenario: Empty state with action
- **WHEN** rendering `<.EmptyState title="No users" action={...}>`
- **THEN** the empty state message and action button are displayed

### Requirement: FilterBar component
The system SHALL provide a `<.FilterBar>` component with configurable filter fields, apply/reset buttons, and a callback event when filters change.

#### Scenario: Filter bar renders fields
- **WHEN** rendering `<.FilterBar fields={@filter_fields} />`
- **THEN** each filter field is rendered as an input

### Requirement: FormSection component
The system SHALL provide a `<.FormSection>` component for grouping related form fields, with title, optional description, and validation error summary.

#### Scenario: Form section with fields
- **WHEN** rendering `<.FormSection title="Details">...</.FormSection>`
- **THEN** a titled section with fields is rendered

### Requirement: LoadingOverlay component
The system SHALL provide a `<.LoadingOverlay>` component that dims content and shows a spinner during async operations.

#### Scenario: Loading overlay active
- **WHEN** rendering `<.LoadingOverlay loading={@loading}>content</.LoadingOverlay>`
- **THEN** the content is dimmed with a spinner when loading is true
