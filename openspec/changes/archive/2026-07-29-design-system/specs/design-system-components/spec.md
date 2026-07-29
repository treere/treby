## ADDED Requirements

### Requirement: Button component
The system SHALL provide a `<.Button>` component supporting variants (primary, secondary, outline, ghost, danger), sizes (sm, md, lg), icon slot, loading state, and disabled state.

#### Scenario: Render primary button
- **WHEN** a template renders `<.Button variant="primary">Save</.Button>`
- **THEN** the output is a `<button>` element with primary variant classes

#### Scenario: Button with disabled state
- **WHEN** a template renders `<.Button disabled>Submit</.Button>`
- **THEN** the button has the `disabled` attribute and appropriate styling

#### Scenario: Button as link
- **WHEN** a template renders `<.Button variant="secondary" navigate={~p"/users"}>Users</.Button>`
- **THEN** the output is an `<a>` tag styled as a secondary button

### Requirement: Card component
The system SHALL provide a `<.Card>` component with header, body, and footer slots, and variants (default, bordered, elevated, flat).

#### Scenario: Basic card
- **WHEN** rendering `<.Card>content</.Card>`
- **THEN** the output is a div with card styling and the content inside

### Requirement: Badge component
The system SHALL provide a `<.Badge>` component with variants (default, success, warning, danger, info) and optional dot indicator.

#### Scenario: Badge with variant
- **WHEN** rendering `<.Badge variant="success">Active</.Badge>`
- **THEN** the output has success variant styling

### Requirement: Modal component
The system SHALL provide a `<.Modal>` component with open/close state, title, body, and footer slots, and support for dismiss-on-backdrop-click and Escape key.

#### Scenario: Modal with title and body
- **WHEN** rendering `<.Modal id="confirm" show>content</.Modal>`
- **THEN** the modal is visible with the title rendered

### Requirement: Dropdown component
The system SHALL provide a `<.Dropdown>` component with a trigger slot and menu items, supporting dividers and disabled items.

#### Scenario: Dropdown with menu items
- **WHEN** rendering `<.Dropdown>` with menu items
- **THEN** clicking the trigger shows the menu

### Requirement: Tabs component
The system SHALL provide a `<.Tabs>` component with tab items and an active tab, supporting both controlled (via assign) and uncontrolled modes.

#### Scenario: Tabs with active tab
- **WHEN** rendering `<.Tabs tabs={@tabs} active_tab={@active}>`
- **THEN** the active tab is highlighted

### Requirement: Spinner component
The system SHALL provide a `<.Spinner>` component for loading states, with configurable size (sm, md, lg).

#### Scenario: Spinner renders
- **WHEN** rendering `<.Spinner />`
- **THEN** an animated spinner element is rendered

### Requirement: Avatar component
The system SHALL provide an `<.Avatar>` component displaying a user image or initials fallback, with configurable size.

#### Scenario: Avatar with image
- **WHEN** rendering `<.Avatar src="/photo.jpg" />`
- **THEN** an image avatar is rendered
