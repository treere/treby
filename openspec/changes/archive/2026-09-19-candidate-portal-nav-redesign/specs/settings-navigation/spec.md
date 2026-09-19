## MODIFIED Requirements

### Requirement: Settings hub uses a sidebar grouped by semantic domain
The system SHALL render the Settings hub as a two-column layout with a left sidebar grouped by semantic domain and a main pane, instead of a flat card grid. The page SHALL have a single vertical scrollbar; the sidebar SHALL NOT create its own independent scroll container.

#### Scenario: Admin sees five groups in fixed order
- **WHEN** an admin visits `/app/settings` (or `/:tenant_slug/app/settings`)
- **THEN** the sidebar shows five groups in order: Organization, Hiring Process, Communication, Scheduling, Privacy & System
- **AND** each group has a heading, an icon, and 2–4 items with title + one-line subtitle

#### Scenario: Main pane shows group overview when no child selected
- **WHEN** an admin is on the hub (`/app/settings`) on desktop
- **THEN** the main pane shows an overview placeholder with group descriptions and quick links to each item

#### Scenario: Mobile collapses to stacked grouped list
- **WHEN** the viewport is below the `lg` breakpoint
- **THEN** the sidebar collapses to a full-width stacked grouped list with the same headings and items, above the main pane, with a single page scroll

#### Scenario: Single page scroll — no dual scrollbars
- **WHEN** a user views any settings page (`/app/settings` or `/app/settings/*`) on desktop at 1280px
- **THEN** there is exactly one vertical scrollbar for the page
- **AND** the sidebar does not render a separate inner scrollbar (no `max-h-[calc(100vh-...)]` + `overflow-y-auto` inner container); it may be `lg:sticky lg:top-20` but scrolls with the page

#### Scenario: Direct link to child still renders shell correctly
- **WHEN** a user opens `/app/settings/pipeline` directly via bookmark
- **THEN** the sidebar renders with Pipeline as the active item and the main pane shows pipeline content within the same single-scroll layout

### Requirement: Child settings pages share the same sidebar shell
The system SHALL render every child settings page inside the same sidebar shell, with the corresponding item marked active. This includes Message Queue after its relocation. Navigating to a child section SHALL bring its content into view even when the user is scrolled down the page.

#### Scenario: Pipeline page shows sidebar
- **WHEN** the user navigates to `/app/settings/pipeline`
- **THEN** the page shows the sidebar on the left and the pipeline content in the main pane
- **AND** a secondary "Back to Settings" link is still available for accessibility

#### Scenario: Selecting a section scrolls content into view on mobile
- **WHEN** a user on a viewport below `lg` taps a sidebar item (e.g., Pipeline) while scrolled at the top or middle of the page
- **THEN** the main content pane (`#settings-main`) is scrolled into view so the section content is visible without manual scrolling past the grouped list

#### Scenario: Selecting a section scrolls content into view on desktop when scrolled down
- **WHEN** a user on desktop is scrolled down the settings page and clicks a sidebar item (e.g., Team)
- **THEN** the main content pane is scrolled into view so the newly-loaded section is visible

#### Scenario: Hub does not auto-scroll
- **WHEN** a user navigates to the hub (`/app/settings`)
- **THEN** the viewport stays at the top showing the grouped overview, not scrolled to the main pane

#### Scenario: Message Queue page shows sidebar
- **WHEN** the user navigates to `/app/messages-queue`
- **THEN** the page shows the settings sidebar on the left and the queue content in the main pane
- **AND** Message Queue is highlighted as active under Communication

## ADDED Requirements

### Requirement: Settings auto-scroll hook is colocated and dependency-free
The system SHALL implement the section scroll behavior with a colocated LiveView hook (`:type={Phoenix.LiveView.ColocatedHook}` named `.SettingsScroll`) attached to the settings shell, without adding external dependencies.

#### Scenario: Hook activates only for child pages
- **WHEN** the settings shell renders with `active_key` set (child page)
- **THEN** the hook scrolls `#settings-main` into view with `{behavior: "smooth", block: "start"}` on mount and on update after navigation

#### Scenario: Hook is inert on hub
- **WHEN** the hub renders with `active_key == nil`
- **THEN** the hook does not trigger any scroll
