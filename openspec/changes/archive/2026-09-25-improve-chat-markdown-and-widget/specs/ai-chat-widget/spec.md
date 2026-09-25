## ADDED Requirements

### Requirement: Markdown tables in assistant replies

Assistant replies SHALL render GFM tables, both while streaming and in the final
persisted message, using the shared Markdown renderer. Wide tables SHALL scroll
horizontally inside the message bubble.

#### Scenario: Reply with a table

- **WHEN** an assistant reply contains a Markdown table
- **THEN** the panel shows a formatted HTML table, not raw pipe characters

#### Scenario: Table during streaming

- **WHEN** a streaming reply contains a complete Markdown table
- **THEN** it is rendered as a table before the reply finishes

### Requirement: Movable and resizable panel

The floating assistant panel SHALL be movable by dragging its header and
resizable from a corner grip. The panel SHALL stay within the visible viewport,
and its position and size SHALL be remembered across page changes, navigation
between navigation groups, and browser refresh.

#### Scenario: Move the panel

- **WHEN** the user drags the panel header
- **THEN** the panel moves with the pointer and cannot be dragged fully off-screen

#### Scenario: Resize the panel

- **WHEN** the user drags the panel's resize grip
- **THEN** the panel changes size within the viewport and never below a usable minimum

#### Scenario: Geometry survives navigation and refresh

- **WHEN** the user moves or resizes the panel and then navigates to another app page or refreshes
- **THEN** the panel reopens at the same position and size

#### Scenario: Viewport shrinks

- **WHEN** the browser window is resized smaller than the stored geometry
- **THEN** the panel is clamped back inside the visible viewport

#### Scenario: Dedicated assistant page unaffected

- **WHEN** the assistant is shown on its dedicated full-width page
- **THEN** no drag or resize affordances are rendered
