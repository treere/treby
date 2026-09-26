# Settings Navigation

## Purpose

Provide a semantically grouped, sidebar-based hub for all workspace settings so users can find controls by domain rather than scanning a flat grid.

## Requirements

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
The system SHALL filter sidebar items by the viewer's effective action permissions, showing only items the viewer is authorized to open, and hide empty groups. No affordance SHALL be rendered for denied actions. Every permission-gated route SHALL also redirect server-side with a permission-denied flash.

#### Scenario: Recruiter sees allowed settings
- **WHEN** a recruiter visits `/app/settings`
- **THEN** the sidebar shows only items whose required action is allowed (e.g. Calendar, My Availability, Language, Message Queue, Data & Privacy personal entry)
- **AND** empty groups are hidden
- **AND** a callout explains that some settings require additional permissions

#### Scenario: Interviewer sees scoped settings
- **WHEN** an interviewer visits `/app/settings`
- **THEN** the sidebar shows only Language, Calendar, My Availability, and Data & Privacy (personal entry)
- **AND** Team, Pipeline Stages, and Message Queue are not visible

#### Scenario: Recruiter with granted pipeline permission sees it
- **WHEN** a recruiter with explicitly allowed `pipeline_manage` visits `/app/settings`
- **THEN** Pipeline Stages appears alongside their other allowed items

#### Scenario: Denied direct navigation redirects
- **WHEN** a user without the page's required action opens its bookmark
- **THEN** the system redirects to the dashboard with a permission-denied flash

#### Scenario: Admin sees all items including Message Queue
- **WHEN** an admin visits `/app/settings`
- **THEN** all items across the five groups are visible including Message Queue under Communication
- **AND** the total count reflects the addition of Message Queue

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

### Requirement: Settings auto-scroll hook is colocated and dependency-free
The system SHALL implement the section scroll behavior with a colocated LiveView hook (`:type={Phoenix.LiveView.ColocatedHook}` named `.SettingsScroll`) attached to the settings shell, without adding external dependencies.

#### Scenario: Hook activates only for child pages
- **WHEN** the settings shell renders with `active_key` set (child page)
- **THEN** the hook scrolls `#settings-main` into view with `{behavior: "smooth", block: "start"}` on mount and on update after navigation

#### Scenario: Hook is inert on hub
- **WHEN** the hub renders with `active_key == nil`
- **THEN** the hook does not trigger any scroll

### Requirement: Setting links preserve existing routes
The system SHALL keep all existing settings and queue routes unchanged; the sidebar links navigate to the same paths as before.

#### Scenario: Bookmark stability
- **WHEN** a user has a bookmark to `/app/settings/team`
- **THEN** the bookmark continues to work and renders inside the new sidebar shell

#### Scenario: Message Queue bookmark stability
- **WHEN** a user has a bookmark to `/app/messages-queue`
- **THEN** the bookmark continues to work and renders inside the new sidebar shell under Settings → Communication

### Requirement: Company Availability is discoverable from two groups without duplicating routes
The system SHALL expose Company Availability primarily under Organization and with a secondary link row under Scheduling that navigates to the same route, without creating a second route.

#### Scenario: Company Availability appears under Organization
- **WHEN** an admin views the sidebar
- **THEN** "Company Availability" appears under Organization with an `Admin` badge

#### Scenario: Scheduling has a cross-link to Company Availability
- **WHEN** an admin views the Scheduling group
- **THEN** a muted row "Manage company defaults →" links to the same Company Availability route

### Requirement: Sidebar respects light and dark themes
The system SHALL render the sidebar with correct contrast in both light and dark themes using SaaS minimal tokens.

#### Scenario: Dark theme contrast passes
- **WHEN** the theme is dark
- **THEN** sidebar headings, item text, group separators, and active states use `dark:` variants (`dark:bg-zinc-800`, `dark:text-zinc-100`, `dark:border-zinc-700`) and pass axe contrast checks via `node scripts/screenshots.mjs --axe`
