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
