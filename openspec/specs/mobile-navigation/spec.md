# Mobile Navigation

## Purpose

Provide responsive navigation that adapts between mobile hamburger menu and desktop inline nav links.

## Requirements

### Requirement: Mobile navigation toggle
The system SHALL display a hamburger menu button on screens below the `xl` breakpoint (1280px) that toggles a mobile navigation drawer.

#### Scenario: Hamburger button visible below xl
- **WHEN** the viewport width is below 1280px
- **THEN** a hamburger menu button is visible in the navigation bar
- **AND** the inline nav links and right-side group are hidden

#### Scenario: Toggle mobile drawer open
- **WHEN** a user taps the hamburger button
- **THEN** a slide-out navigation drawer opens showing all nav links (Jobs, Candidates, Interviews, Analytics, Settings)
- **AND** a backdrop overlay covers the main content

#### Scenario: Toggle mobile drawer closed
- **WHEN** a user taps the close button or the backdrop overlay
- **THEN** the mobile navigation drawer closes

#### Scenario: Navigate from mobile drawer
- **WHEN** a user taps a nav link in the mobile drawer
- **THEN** the drawer closes and the user navigates to the selected page

### Requirement: Inline nav only at xl and above
The system SHALL display nav links inline on screens at or above the `xl` breakpoint (1280px) with no hamburger button. Below `xl` the navigation collapses into the drawer.

#### Scenario: Inline nav display
- **WHEN** the viewport width is 1280px or above
- **THEN** nav links are displayed inline in the navigation bar
- **AND** the notification bell, theme toggle, locale switcher, user name, and logout are visible inline
- **AND** no hamburger button is visible

### Requirement: Mobile drawer includes theme toggle
The mobile navigation drawer SHALL include a theme toggle control alongside the locale switcher so users can switch themes without leaving the drawer.

#### Scenario: Theme toggle in mobile drawer
- **WHEN** a user opens the mobile navigation drawer below the `sm` breakpoint
- **THEN** a theme toggle control is visible next to the locale switcher
- **AND** activating it changes the active theme immediately
