# AI Chat Widget

## Purpose

Provide a floating, on-every-page assistant panel for authenticated team members, with streaming replies, open-state persistence, and non-obstructive layout over the host page. (TBD: expand with cross-page navigation behavior.)

## Requirements

### Requirement: Global assistant widget

The system SHALL render a floating assistant panel on every authenticated app page through the shared app layout. The panel SHALL be openable and closable from a persistent trigger. It SHALL NOT render on the candidate portal or public career pages.

#### Scenario: Available on app pages
- **WHEN** an authenticated team member visits any app page (dashboard, jobs, candidates, settings)
- **THEN** the assistant trigger is present and can open the panel

#### Scenario: Not available on the portal
- **WHEN** a candidate accesses `/:tenant_slug/portal/*` or a public career page
- **THEN** no assistant trigger or panel is rendered

#### Scenario: Open and close
- **WHEN** the user clicks the trigger
- **THEN** the panel becomes visible, and clicking the close control hides it

### Requirement: Non-obstructive panel

The panel SHALL float above the page as a fixed-size surface and SHALL NOT prevent interaction with the page underneath while open.

#### Scenario: Page usable with panel open
- **WHEN** the panel is open
- **THEN** the user can still scroll, click, and submit forms on the page beneath it

### Requirement: Open state persistence

The system SHALL remember whether the panel was open across page changes and browser refresh. Open state SHALL be stored client-side and SHALL NOT be used to store message content.

#### Scenario: Open survives page change
- **WHEN** the panel is open and the user navigates to another app page
- **THEN** the panel is open on the new page

#### Scenario: Open survives refresh
- **WHEN** the panel is open and the user refreshes the browser
- **THEN** the panel is open after reload

#### Scenario: Closed state respected
- **WHEN** the panel is closed and the user navigates to another app page
- **THEN** the panel stays closed

### Requirement: Streaming with progressive markdown

The system SHALL display assistant replies progressively as tokens stream in, rendered as markdown, and SHALL replace the streaming view with the final persisted message when the reply completes. While a reply is generating, the host page SHALL remain responsive.

#### Scenario: Tokens appear progressively
- **WHEN** the model starts producing a reply
- **THEN** content appears in the panel before the reply is complete

#### Scenario: Markdown during and after streaming
- **WHEN** streamed content contains markdown (lists, bold, code)
- **THEN** it is rendered as formatted HTML while streaming and after completion

#### Scenario: Page responsive during generation
- **WHEN** a reply is being generated
- **THEN** the user can still interact with the host page

### Requirement: Widget across navigation groups

The widget SHALL remain functional when the user navigates between app pages that belong to different navigation groups (for example from the main app to settings), preserving the conversation content.

#### Scenario: Navigate between groups
- **WHEN** the user moves from a main app page to a settings page while the panel is open
- **THEN** the panel remains available and shows the same conversation

### Requirement: Markdown tables in assistant replies

Assistant replies SHALL render GFM tables, both while streaming and in the final persisted message, using the shared Markdown renderer. Wide tables SHALL scroll horizontally inside the message bubble.

#### Scenario: Reply with a table
- **WHEN** an assistant reply contains a Markdown table
- **THEN** the panel shows a formatted HTML table, not raw pipe characters

#### Scenario: Table during streaming
- **WHEN** a streaming reply contains a complete Markdown table
- **THEN** it is rendered as a table before the reply finishes

### Requirement: Movable and resizable panel

The floating assistant panel SHALL be movable by dragging its header and resizable from a corner grip. The panel SHALL stay within the visible viewport, and its position and size SHALL be remembered across page changes, navigation between navigation groups, and browser refresh.

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
