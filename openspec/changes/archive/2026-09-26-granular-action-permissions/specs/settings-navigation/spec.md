## MODIFIED Requirements

### Requirement: Settings hub uses a sidebar grouped by semantic domain
The system SHALL render the Settings hub as a two-column layout with a sticky left sidebar grouped by semantic domain and a main pane, instead of a flat card grid. The page SHALL have a single vertical scrollbar; the sidebar SHALL NOT create its own independent scroll container.

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

### Requirement: Sidebar items are permission-aware
The system SHALL filter sidebar items by the viewer's effective action permissions, showing only items the viewer is authorized to open, and hide empty groups. No affordance SHALL be rendered for denied actions.

#### Scenario: Interviewer sees scoped settings
- **WHEN** an interviewer visits `/app/settings`
- **THEN** the sidebar shows only Language, Calendar, My Availability, and Data & Privacy (personal entry)
- **AND** empty groups are hidden
- **AND** a callout explains that some settings require additional permissions

#### Scenario: Recruiter with granted pipeline permission sees it
- **WHEN** a recruiter with explicitly allowed `pipeline_manage` visits `/app/settings`
- **THEN** Pipeline Stages appears alongside their other allowed items

#### Scenario: Admin sees all items including Message Queue
- **WHEN** an admin visits `/app/settings`
- **THEN** all items across the five groups are visible including Message Queue under Communication
- **AND** the total count reflects the addition of Message Queue

#### Scenario: Denied item has no link anywhere
- **WHEN** a user lacks the action for a settings item
- **THEN** no sidebar entry, quick link, or overview card links to that item

### Requirement: Active item is highlighted and accessible
The system SHALL visually highlight the active sidebar item and mark it with `aria-current="page"`.

#### Scenario: Active item has distinct styling
- **WHEN** the user is on `/app/settings/pipeline`
- **THEN** the Pipeline item in the sidebar has `bg-zinc-100 text-zinc-900 font-medium` (light) / `bg-zinc-800` (dark) and `aria-current="page"`
- **AND** all other items use muted styling

#### Scenario: Deep links preserve active state
- **WHEN** the user opens `/app/settings/webhooks` directly via bookmark
- **THEN** the sidebar renders with Webhooks as the active item

#### Scenario: Message Queue active state
- **WHEN** the user opens `/app/messages-queue` directly via bookmark or via sidebar
- **THEN** the sidebar renders with Message Queue as the active item under Communication

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

### Requirement: Setting links preserve existing routes
The system SHALL keep all existing settings and queue routes unchanged; the sidebar links navigate to the same paths as before.

#### Scenario: Bookmark stability
- **WHEN** a user has a bookmark to `/app/settings/team`
- **THEN** the bookmark continues to work and renders inside the new sidebar shell

#### Scenario: Message Queue bookmark stability
- **WHEN** a user has a bookmark to `/app/messages-queue`
- **THEN** the bookmark continues to work and renders inside the new sidebar shell under Settings → Communication

### Requirement: Denied direct navigation redirects with flash
The system SHALL guard every permission-gated route server-side: direct navigation without the required action SHALL redirect to the workspace dashboard with a permission-denied flash, even if the link was never rendered.

#### Scenario: Bookmark to denied page redirects
- **WHEN** a user without `webhooks_manage` opens a bookmark to the webhooks settings page
- **THEN** the system redirects to the dashboard with a permission-denied flash
