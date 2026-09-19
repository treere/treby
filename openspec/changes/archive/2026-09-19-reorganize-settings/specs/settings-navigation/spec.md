## ADDED Requirements

### Requirement: Settings hub uses a sidebar grouped by semantic domain
The system SHALL render the Settings hub as a two-column layout with a sticky left sidebar grouped by semantic domain and a main pane, instead of a flat card grid.

#### Scenario: Admin sees five groups in fixed order
- **WHEN** an admin visits `/app/settings` (or `/:tenant_slug/app/settings`)
- **THEN** the sidebar shows five groups in order: Organization, Hiring Process, Communication, Scheduling, Privacy & System
- **AND** each group has a heading, an icon, and 2–4 items with title + one-line subtitle

#### Scenario: Main pane shows group overview when no child selected
- **WHEN** an admin is on the hub (`/app/settings`) on desktop
- **THEN** the main pane shows an overview placeholder with group descriptions and quick links to each item

#### Scenario: Mobile collapses to stacked grouped list
- **WHEN** the viewport is below the `lg` breakpoint
- **THEN** the sidebar collapses to a full-width stacked grouped list with the same headings and items

### Requirement: Sidebar items are role-aware
The system SHALL filter sidebar items by the viewer's role, showing only items the viewer is authorized to open, and hide empty groups.

#### Scenario: Member sees reduced settings
- **WHEN** a non-admin member visits `/app/settings`
- **THEN** the sidebar shows only Language, Calendar, My Availability, and Data & Privacy (personal entry)
- **AND** empty groups are hidden
- **AND** a callout explains that some settings require admin
- **AND** Message Queue is not visible

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
The system SHALL render every child settings page inside the same sidebar shell, with the corresponding item marked active. This includes Message Queue after its relocation.

#### Scenario: Pipeline page shows sidebar
- **WHEN** the user navigates to `/app/settings/pipeline`
- **THEN** the page shows the sidebar on the left and the pipeline content in the main pane
- **AND** a secondary "Back to Settings" link is still available for accessibility

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
